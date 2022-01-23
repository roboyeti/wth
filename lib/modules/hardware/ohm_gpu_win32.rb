# Author: BeRogue01
# License: See LICENSE file
# Date: 1/2022
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# https://github.com/WinRb/WinRM
# https://github.com/LibreHardwareMonitor/LibreHardwareMonitor
#
# Enable-PSRemoting -Force
# gem install -r winrm
# NOT NEEDED?  Get-PNPDevice -InstanceID '#{g1}' | ConvertTo-Json
#
# TODO - add OpenHardwareMonitor link and test
#
require 'winrm'

class Modules::OhmGpuWin32 < Modules::Base #Modules::OhmWin32
  using IndifferentHash  

  GPU_MANUFACTURER = {
    'nvidia' => 'nvidia',
    'intel corporation' => 'intel',
    'amd' => 'amd'
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

  attr_reader :lifespan, :cache

  def initialize(p={})
    super
    @user = @config[:user] || 'administrator'
    @password = @config[:password] || ''
    @source = @title = "LibraHardwareMonitor"
    if !@password
      puts "Password for Ohm User #{@user}:"
      @password = ARGF.gets
    end
    @port = @config["port"] || 5985
    @protocol = @config["protocol"] || 'http'
    @lifespan = @config["lifespan"] || 120
    @lifespan = 60 if @lifespan < 120
    @threads = {}
    @conn = {}
    @shell = {}
    cache_dir = 'tmp/wmi_ohm_cache'    
    @cache = OpenStruct.new({
      default: Lightly.new(dir: cache_dir, life: @lifespan, hash: false),
      sensors: Lightly.new(dir: cache_dir, life: 12, hash: false),
    })
    @headers = ['Name','Device','Type','Bus/Id','Bios/Cores','Driver Version','Mem(GB)','Pwr(W)','Temp','HotSpot','Fan(rpm)','Fan%','Clk','MemClk','BusLoad/Speed','CoreLoad','MemLoad']
  end

  def flush
    @cache.each_pair{|k,v|
      v.flush
    }
  end

  def request(ckey,name,cmd)
    out = @shell[ckey].run("#{cmd} | ConvertTo-Json").output
    jout = JSON.parse(out)
    @dump && dump_response("#{ckey}_#{name}",["URL::#{cmd}",jout])
    jout
  end
  
  # The check for Open/Libre Hardware Monitors is complicated, because it doesn't provide that much data, but does
  # provide good sensor info, especially for GPUs.
  def check(addr,name)
    host,port,src,user,pass = addr.split(':')
    if src && src == "lhm"
      @source = "LibreHardwareMonitor"
    end
    user = user && !user.empty? ? user : @user
    pass = pass && !user.empty? ? pass : @password
    port = port && !port.empty? ? port : @port    

    ckey = "#{host}_#{port}"
    res = { "gpus" => {}, "cpus" => {} }

    ret = if @threads[ckey]
      val = @threads[ckey].value!(0.25)
      if val
        @threads.delete(ckey)
        val
      else
        warn_structure(format(name,addr,res))
      end
    else
      @threads[ckey] = Concurrent::Promises.future(ckey) do |ckey|
        @conn[ckey] = WinRM::Connection.new({ 
            endpoint: "#{@protocol}://#{host}:#{port}/wsman",
            user: user,
            password: pass
        })
        @shell[ckey] = @conn[ckey].shell(:powershell)
        
        cmd = CMDS["ohm_sensors"].gsub('%SOURCE%',@source)
        sensors = cache.sensors.get("ohm_sensors_#{ckey}"){ request(ckey,'ohm_sensors',cmd).map{|r| fix_keys(r,[/^/,'Ohm']) } }
        cmd = CMDS["ohm_hardware"].gsub('%SOURCE%',@source)
        hardware = cache.sensors.get("ohm_hardware_#{ckey}"){ request(ckey,'ohm_hardware',cmd).map{|r| fix_keys(r,[/^/,'Ohm']) } }
    
        res["gpus"] = check_gpu(host,port,sensors,hardware)
        res["cpus"] = check_cpu(host,port,sensors,hardware)
        res["mem"] = check_mem(host,port,sensors,hardware)
    
        format(name,addr,res)
      end
        warn_structure(format(name,addr,res))
    end
    return ret
  rescue => e
    @threads.delete(ckey)
    raise e
  end

  def check_cpu(host,port,sensors,hardware)
    cpus = {}
    hardware.each{|h|
      ohm_id = h["ohm_identifier"]
      next if ohm_id !~ /\/*cpu/
      store_it("#{host}_cpu_name",h["ohm_name"])# if @store_cpu
      dnil,dman,did = ohm_id.split('/')
      cpus[did] = {}
      cpus[did].merge!(h)
      cpus[did]["device_id"] = did
      cpus[did]["device_manufacturer"] = dman
      cpus[did]["pci"] = "-"
      core_cnt = 0
      sensors.each{|s|
        if s["ohm_parent"] == ohm_id
          skey = fix_key("#{s["ohm_name"]}_#{s["ohm_sensor_type"]}")
          cpus[did][skey] = s["ohm_value"]
          core_cnt = core_cnt + 1 if (s["ohm_name"] =~ /^(CPU|Core)/) && (s["ohm_sensor_type"] == "Clock")
        end
      }
      cpus[did]["cores"] = core_cnt

    }
    cpus    
  end

  def check_mem(host,port,sensors,hardware)
    o = {}
    hardware.each{|h|
      ohm_id = h["ohm_identifier"]
      next if ohm_id !~ /\/ram/
      dnil,dman,did = ohm_id.split('/')
      did = "/#{dman}"
      o.merge!(h)
      o["device_id"] = did
      o["pci"] = "-"
      sensors.each{|s|
        if s["ohm_parent"] == ohm_id
          skey = fix_key("#{s["ohm_name"]}_#{s["ohm_sensor_type"]}")
          o[skey] = s["ohm_value"]
        end
      }
      break
    }
    o
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

    ckey = "#{host}_#{port}"

    # Call CIM_PCVidController
    cmd = CMDS['gpu_wmi_cimvid']
    wmi_vid = cache.default.get("gpu_wmi_cimvid_#{ckey}") { request(ckey,'gpu_cimvid',CMDS['gpu_wmi_cimvid']) }
    wmi_vid = wmi_vid.is_a?(Hash) ? [ wmi_vid ] : wmi_vid
    wmi_vid.each_with_index{|wv,idx|
      gpus_temp = {}
      # Use PNPDeviceID to find in PnpDeviceProperty
      cmd = CMDS['gpu_wmi_pnpdevprop'].gsub('%PNPDeviceID%',wv["PNPDeviceID"].gsub(/\\/) { |x| "\\#{x}" })
      cmd.gsub!('%KEYS%',PNPDEVKEYS.join(','))
      wmi_pnpd = cache.default.get("gpu_wmi_pnpdevprop_#{ckey}_#{idx}"){|e| request(ckey,'gpu_pnpdevprop',cmd); }

      gpus_temp = fix_keys(wv)

      wmi_pnpd.each{|item|
        sk = fix_key(item["KeyName"],['DEVPKEY_',''])
        gpus_temp[sk] = item["Data"]
      }
  
      # Lookup Win32 Registry entry
      cmd = CMDS['gpu_wmi_reg'].gsub('%DeviceDriver%',gpus_temp["device_driver"].gsub(/\\/) { |x| "\\#{x}" })
      reg_vid = cache.default.get "gpu_wmi_reg_#{ckey}_#{idx}" do
        request(ckey,'gpu_reg',cmd)
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
      gpu_ohm_type = "/gpu-#{gpu_m}"
      gpus_manufact[gpu_ohm_type] ||= []
      gpus_manufact[gpu_ohm_type] << bus_num
      gpus[bus_num]["ohm_device_key"] = gpu_ohm_type
    }

    gpus_manufact.each_pair{|k,v|
      gpus_manufact[k] = v.sort
    }

    hardware.each{|h|
      ohm_id = h["ohm_identifier"]
      next if ohm_id !~ /\/gpu-/
      dnil,dman,did = ohm_id.split('/')
      dman = "/#{dman}"
      bus = gpus_manufact[dman][did.to_i]
      gpus[bus].merge!(h)
      gpus[bus]["device_id"] = did
      sensors.each{|s|
        if s["ohm_parent"] == ohm_id
          skey = fix_key("#{s["ohm_name"]}_#{s["ohm_sensor_type"]}")
          gpus[bus][skey] = s["ohm_value"]
        end
      }
    }

    gpus
  end

  def format(name,addr,res)
    host,port,src,user,pass = addr.split(':')

    o = node_structure
    o.name = name
    o.address = host
    res["gpus"].each_pair{|gk,gv|
      g = GpuDevice.new
      g.name = gv["name"]
      g.manufacturer = gv["device_manufacturer"]
      g.id = gv["device_id"]
      g.pci = gv["device_bus_number"]
      g.location = gv["device_location_info"]
      g.bios = gv["bios_string"]
      g.driver_date = gv["driver_date"]
      g.driver = gv["driver_version"]
# Bug in LHM: memory is duplicated from the first card detected. Filed bug @
# https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/issues/636
#      g.memory_free = gv["gpu_memory_free_small_data"].to_f / 1024
#      g.memory_used = gv["gpu_memory_used_small_data"].to_f / 1024
#      g.memory_total = gv["gpu_memory_total_small_data"].to_f / 1024
      g.memory_total = gv["qw_memory_size"].to_f / 1073741824
      g.temperature = gv["gpu_core_temperature"].to_i
      g.temperature_hotspot = gv["gpu_hot_spot_temperature"].to_i
      g.power = gv["gpu_package_power"].to_i
      g.fan_rpm = gv["gpu_fan_fan"].to_i
      g.fan_percent = gv["gpu_fan_control"].to_i
      g.clock = gv["gpu_core_clock"].to_i
      g.memory_clock = gv["gpu_memory_clock"].to_i
      g.bus_load = gv["gpu_bus_load"].to_i
      g.core_load = gv["gpu_core_load"].to_i
      g.memory_load = gv["gpu_memory_controller_load"].to_i
      g.pci_rx = gv["gpu_pcie_rx_throughput"].to_f / 100000
      g.pci_tx = gv["gpu_pcie_tx_throughput"].to_f / 100000
      o.gpu[gk] = g
    }

    res["cpus"].each_pair{|ck,cv|
      c = CpuDevice.new
      c.name = cv["ohm_name"]
      c.manufacturer = cv["device_manufacturer"]
      c.id = cv["device_id"]
      c.pci = "-"
      c.cores = cv["cores"].to_i
      c.memory_free = res["mem"]["memory_available_data"].to_f
      c.memory_used = res["mem"]["memory_used_data"].to_f
      c.memory_total = c.memory_free + c.memory_used
      c.memory_size = "GB"
      c.temperature = (cv["cpu_package_temperature"] || cv["core_tdie_temperature"]).to_i
      c.temperature_max = (cv["core_max_temperature"] || cv["core_tctl_temperature"]).to_i
      c.power = (cv["cpu_package_power"] || cv["package_power"]).to_i
      c.fan_rpm = 0
      c.fan_percent = 0
      c.clock = (cv["cpu_core1_clock"] || cv["core1_clock"]).to_i
      c.bus_speed = cv["bus_speed_clock"].to_i
      c.core_load = cv["cpu_total_load"].to_i
      c.memory_load = res["mem"]["memory_load"].to_i
      o.cpu[ck] = c
    }
    o.mem = res["mem"]
    o
  end

  def warn_structure(h)
    h.gpu[0] = GpuDevice.new
    h.gpu[0].name = colorize("pending...",$color_warn)
    h.state = 'pending_update'
    h
  end

  def down_structure(h)
    h.gpu[0] = GpuDevice.new
    h.gpu[0].name = colorize("down",$color_alert)
    h
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      item["gpu"].keys.sort.each_with_index{|bus,i|
        g = item["gpu"][bus]
        rows << [
          item.name.capitalize, colorize(g.name,:bright_cyan), colorize(g.type.upcase,:bright_cyan), g.pci, g.bios, g.driver, g.memory_total.round, g.power,
          g.temperature, g.temperature_hotspot, g.fan_rpm, g.fan_percent,
          g.clock, g.memory_clock, g.bus_load, g.core_load, g.memory_load
        ]
      }
      item["cpu"].keys.sort.each_with_index{|bus,i|
        g = item["cpu"][bus]
        rows << [
          item.name.capitalize, colorize(g.name,:bright_magenta), colorize(g.type.upcase,:bright_magenta), g.id, "#{g.cores} cores", "", g.memory_total.round, g.power,
          g.temperature, g.temperature_max, g.fan_rpm, g.fan_percent,
          g.clock, "", g.bus_speed, g.core_load, g.memory_load
        ]
      }
    end
  end

  def node_structure
    HostStructure.new
  end

end
