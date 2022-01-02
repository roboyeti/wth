# https://github.com/WinRb/WinRM
# https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
# 
# Enable-PSRemoting -Force
# gem install -r winrm
# NOT NEEDED?  Get-PNPDevice -InstanceID '#{g1}' | ConvertTo-Json
require 'winrm'
require 'lightly'

class Modules::OhmGpuWin32 < Modules::Base #Modules::OhmWin32
  using IndifferentHash  

  GPU_MANUFACTURER = {
    'nvidia' => 'nvidia',
    'intel corporation' => 'intel',
  }

  PNPDEVKEYS = [
    :DEVPKEY_Device_BusNumber,
    :DEVPKEY_Device_Driver,
    :DEVPKEY_Device_DriverVersion,
    :DEVPKEY_Device_ReportedDeviceIdsHash,
    :DEVPKEY_Device_IsRebootRequired,
    :DEVPKEY_Device_IsPresent,
    :DEVPKEY_Device_HasProblem,
    :DEVPKEY_Device_LocationInfo,
    :DEVPKEY_Device_Manufacturer,
  ]

  CMDS = {
    'ohm_hardware' => %q[Get-WMIObject -namespace 'root/%SOURCE%' -Class Hardware | Select-Object HardwareType, Parent, Identifier,InstanceId, Name | Sort-Object Parent,Identifier],
    'ohm_sensors'   => %q[Get-wmiobject -namespace 'root/%SOURCE%' -Class Sensor | Select-Object Parent, Identifier,InstanceId, Name, Value, SensorType | Sort-Object Parent, Identifier],
    'gpu_wmi_cimvid' => %q[Get-CimInstance -ClassName CIM_PCVideoController | Select-Object Name, PNPDeviceID],
    'gpu_wmi_pnpdevprop' => %q[Get-PnpDeviceProperty -InstanceID '%PNPDeviceID%' -KeyName %KEYS% | Select-Object KeyName,Data],
    'gpu_wmi_reg' => %q[Get-ItemProperty -Path 'HKLM:\\SYSTEM\\ControlSet001\\Control\\Class\\%DeviceDriver%' | Select-Object HardwareInformation.qwMemorySize, HardwareInformation.BiosString, DriverDate, DriverVersion],
    'gpu_wmi_' => %q[],
    'cpu_wmi_' => %q[]
  }

  SOURCES = {
    'lhm' => "LibreHardwareMonitor",
    'libre' => "LibreHardwareMonitor",
    'ohm' => "OpenHardwareMonitor",
    'open' => "OpenHardwareMonitor",
  }

  def initialize(p={})
    super
    @user = p[:user] || 'allend'
    @password = p[:password] || '!Dr00gzy!'
    @source = "OpenHardwareMonitor"
    if !@password
      puts "Password for Ohm User #{@user}"
      @password = ARGF.gets
    end
    @port = p["port"] || 5985
    @protocol = p["protocol"] || 'http'
    @lifespan = p["lifespan"] || 120
    @lifespan = 60 if @lifespan < 120
    @cache = {}
  end

  def request(cmd)
    @debug && puts("COMMAND: #{cmd}")
    out = @shell.run("#{cmd} | ConvertTo-Json").output
    @debug && puts(out)
    JSON.parse(out)
  end
  
  # The check for Open/Libre Hardware Monitors is complicated, because it doesn't provide that much data, but does
  # provide good sensor info, especially for GPUs.
  def check(ip,name)
    host,port,src = ip.split(':')
    if src && src == "lhm"
      @source = "LibreHardwareMonitor"
    end
    port = port && !port.empty? ? port : @port    
    conn = WinRM::Connection.new({ 
        endpoint: "#{@protocol}://#{host}:#{port}/wsman",
        user: @user,
        password: @password
    })
    @shell = conn.shell(:powershell)
    res = { "gpus" => {} }

    ckey = "#{host}_#{port}"
    cache = @cache[ckey] ||= Lightly.new dir: 'tmp/wmi_ohm_cache', life: @lifespan, hash: false
    cache2 = @cache["sensors_#{ckey}"] ||= Lightly.new dir: 'tmp/wmi_ohm_cache', life: 12, hash: false

    cmd = CMDS["ohm_sensors"].gsub('%SOURCE%',@source)
    @sensors = cache2.get("ohm_sensors_#{ckey}"){ request(cmd).map{|r| fix_keys(r,[/^/,'Ohm']) } }
    cmd = CMDS["ohm_hardware"].gsub('%SOURCE%',@source)
    @hardware = cache2.get("ohm_hardware_#{ckey}"){ request(cmd).map{|r| fix_keys(r,[/^/,'Ohm']) } }

    gpu = check_gpu(host,port,@sensors,@hardware)

    res["gpus"] = gpu

    res
    format(name,ip,res)
  end

  def check_cpu

  end

  # * Get the CIM_PCVideoController.  Note, the ordering is worthless
  # * Use the PNPDeviceID to get the PnpDeviceProperty
  # * Use the Device_Driver to get the driver registry entry
  # * Resort everything based on PCI BUS#, derived from PnpDeviceProperty
  # * Build a OHM/LHM compatible id (this diverges between the two)
  # * Fix up keys along the way to be snakecase
  def check_gpu(host,port,sensors,hardware)
    gpus = {}
    gpus_manufact = {}

    # Setup cache
    ckey = "#{host}_#{port}"
    cache = @cache[ckey]

    # Call CIM_PCVidController
    cmd = CMDS['gpu_wmi_cimvid']
    wmi_vid = cache.get("gpu_wmi_cimvid_#{ckey}") { request(CMDS['gpu_wmi_cimvid']) }

    wmi_vid.each_with_index{|wv,idx|
      gpus_temp = {}
      # Use PNPDeviceID to find in PnpDeviceProperty
      cmd = CMDS['gpu_wmi_pnpdevprop'].gsub('%PNPDeviceID%',wv["PNPDeviceID"].gsub(/\\/) { |x| "\\#{x}" })
      cmd.gsub!('%KEYS%',PNPDEVKEYS.join(','))
      wmi_pnpd = cache.get("gpu_wmi_pnpdevprop_#{ckey}_#{idx}"){|e| request(cmd); }

      gpus_temp = fix_keys(wv)

      wmi_pnpd.each{|item|
        sk = fix_key(item["KeyName"],['DEVPKEY_',''])
        gpus_temp[sk] = item["Data"]
      }
  
      # Lookup Win32 Registry entry
      cmd = CMDS['gpu_wmi_reg'].gsub('%DeviceDriver%',gpus_temp["device_driver"].gsub(/\\/) { |x| "\\#{x}" })
      reg_vid = cache.get "gpu_wmi_reg_#{ckey}_#{idx}" do
        request(cmd)
      end

      gpus_temp.merge!(fix_keys(reg_vid,['HardwareInformation.','']))
      if gpus_temp["bios_string"].is_a?(Array)
        gpus_temp["bios_string"] = "unknown"
      elsif gpus_temp["bios_string"] =~ /^Version/
        gpus_temp["bios_string"].gsub!(/^Version/,'')
      end

      bus_num = gpus_temp["device_bus_number"].to_i
      gpus[bus_num] = gpus_temp

      # Example OHM id: /gpu-nvidia/0
      # The ending number is order position AFTER sorting by Bus#, I think, so we finish this later
      # to map to OHM/LHM
      # gpus_temp["device_manufacturer"]
      gpu_m = GPU_MANUFACTURER[gpus_temp["device_manufacturer"].downcase]
      #puts gpu_m
      gpu_ohm_type = "/gpu-#{gpu_m}"
      gpus_manufact[gpu_ohm_type] ||= []
      gpus_manufact[gpu_ohm_type] << bus_num
      gpus[bus_num]["ohm_device_key"] = gpu_ohm_type
    }

    gpus_manufact.each_pair{|k,v|
      gpus_manufact[k] = v.sort
    }

    @hardware.each{|h|
     ohm_id = h["ohm_identifier"]
     next if ohm_id !~ /\/gpu-/
     dnil,dman,did = ohm_id.split('/')
     dman = "/#{dman}"
     bus = gpus_manufact[dman][did.to_i]
     gpus[bus].merge!(h)
     gpus[bus]["device_id"] = did
     @sensors.each{|s|
       if s["ohm_parent"] == ohm_id
          skey = fix_key("#{s["ohm_name"]}_#{s["ohm_sensor_type"]}")
          gpus[bus][skey] = s["ohm_value"]
       end
     }
   }

    gpus
  end

  def node_structure
    OpenStruct.new({
      name:     "",
      address:  "",
#      uptime:   0,
#      power_total:    0,
      target:   "",
      time:     Time.now,
      gpu:      {},
    })
  end

  def gpu_structure
    OpenStruct.new({
      name: "",
      manufacturer: "",
      id: "",
      pci: "",
      location: "",
      bios: "",
      driver_date: "",
      driver: "",
      memory_free: 0,
      memory_used: 0,
      memory_total: 0,
      memory_size: "MB",
      temperature: 0,
      temperature_hotspot: 0,
      power: 0,
      fan_rpm: 0,
      fan_percent: 0,
      clock: 0,
      memory_clock: 0,
      bus_load: 0,
      core_load: 0,
      memory_load: 0,
      pci_rx: 0,
      pci_tx: 0,
    })
  end

  def gpu_map
    {
      name: "name",
      manufacturer: "device_manufacturer",
      id: "device_id",
      pci: "device_bus_number",
      location: "device_location_info",
      bios: "bios_string",
      driver_date: "driver_date",
      driver: "driver_version",
      memory_free: "gpu_memory_free_small_data",
      memory_used: "gpu_memory_used_small_data",
      memory_total: "gpu_memory_total_small_data",
      temperature: "gpu_core_temperature",
      temperature_hotspot: "gpu_hot_spot_temperature",
      power: "gpu_package_power",
      fan_rpm: "gpu_fan_fan",
      fan_percent: "gpu_fan_control",
      clock: "gpu_core_clock",
      memory_clock: "gpu_memory_clock",
      bus_load: "gpu_bus_load", # haha
      core_load: "gpu_core_load",
      memory_load: "gpu_memory_controller_load",
      pci_rx: "gpu_pc_ie_rx_throughput",
      pci_tx: "gpu_pc_ie_tx_throughput",
    }
  end

  def format(name,ip,res)
    o = node_structure
    o.name = name
    o.address = ip
    res["gpus"].each_pair{|gk,gv|
      g = gpu_structure
      gpu_map.each_pair{|k,v|
        g.send("#{k}=",gv[v])
      }
      g["pci_rx"] = g["pci_rx"].to_f / 100000
      g["pci_tx"] = g["pci_tx"].to_f / 100000
      o.gpu[gk] = g
    }
    o
  end

  def console_out(data)
    hash = data[:addresses]
    rows = []
    title = "LibreHardwareMonitor" #Coin Portfolio: https://www.coingecko.com : Last checked #{data[:last_check_ago].ceil(2)} seconds ago"
    headers = ['Name','Card','Bus#','Bios','Driver','Mem(MB)','Pwr','Temp','HotSpot','Fan','Fan%','Clock','MemClk']

    total_value = 0.0
    total_profit = 0.0
	
    hash.keys.sort.each_with_index{|addr,i|
      h = hash[addr]
  
#      next if h.down == true
      if h.down == true
        h["gpu"][0] = gpu_structure
        g.name = colorize("down",$color_alert)
      end
      h["gpu"].keys.sort.each_with_index{|bus,i|
        g = h["gpu"][bus]
        rows << [
          h.name, g.name, g.pci, g.bios, g.driver, g.memory_total, g.power,
          g.temperature, g.temperature_hotspot, g.fan_rpm, g.fan_percent, g.clock, g.memory_clock
        ]
      }
    }

#pp headers
#pp rows
    table_out(headers,rows,title)
#puts headers.join(',')
#rows.each{|r|
  #puts r.join(',')
#}
#exit
  end

  def fix_keys(hsh,*extra)
    new_hash = {}
    hsh.each_pair{|k,v|
      new_hash[fix_key(k,*extra)] = v
    }
    new_hash
  end

  def fix_key(k,*extra)
    key = k.dup
    if !extra.empty?
      extra.each{|e|
        key.gsub!(e[0],e[1])
      }
    end
    key.gsub(/[\.|\-|\=\s]/,'_').snakecase  
  end
end

#require 'winrm'
#require 'json'
#
#ohm = OhmWin32.new({ :user => 'allend', :password => '!Dr00gzy!'})
#r = ohm.check("192.168.0.122::lhm","Vendetta")
#pp r
#a = { addresses: { r.name => r } }
#pp a
#pp ohm.console_out(a)

