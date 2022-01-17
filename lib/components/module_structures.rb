# This file is in progress ... transition happening from one struct def method to
# something new ...
#
# Don't mess with this please
#
  set_time = proc { self.time = Time.now }
  root_struct = {
    name:     '',
    address:  '',
    port:     0,
    ip:       "",
    time:     '',
    down:     false,
    target:   '',
    state:    '',
    message:  '',
    error:    '',
    backtrace: [],
  }

  RootStructure = Struct.better(root_struct) { after_create set_time }
  
  HostStructure = Struct.better(root_struct.merge({
        gpu:      {},
        cpu:      {},
        mem:      {},
      })) { after_create set_time }
  
  GpuDevice = Struct.better({
        name: '',
        manufacturer: '',
        id: '',
        pci: '',
        type: 'GPU',
        location: '',
        bios: '',
        driver_date: '',
        driver: '',
        memory_free: 0,
        memory_used: 0,
        memory_total: 0,
        memory_size: 'GB',
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
        pci_tx: 0
      })
  
  CpuDevice = Struct.better({
        name: '',
        id: '0',
        type: 'CPU',
        manufacturer: '',
        pci: '',
        cores: 0,
        memory_free: 0,
        memory_used: 0,
        memory_total: 0,
        memory_size: 'MB',
        temperature: 0,
        temperature_max: 0,
        power: 0,
        fan_rpm: 0,
        fan_percent: 0,
        clock: 0,
        bus_speed: 0,
        core_load: 0,
        memory_load: 0
      })
  
  MiningNode = Struct.better(root_struct.merge({
        miner: '',
        user: '',
        uptime: 0,
        algo: '',
        coin: '',
        pool: '',
        difficulty: 0,
        combined_speed: 0.0,
        max_speed: 0,
        hashes_total: 0,
        total_shares:   0,
        rejected_shares: 0,
        stale_shares:   0,
        invalid_shares: 0,
        power_total:    0,
        revenue:        0.0,
        gpu: {},
        cpu: '',
      })) { after_create set_time }
  
  MiningGpu = Struct.better({
        pci: "0",
        id: 0,
        gpu_speed: 0.0,
        gpu_temp: 0,
        gpu_fan: 0,
        gpu_power: 0,
        speed_unit: '',
        total_shares: 0,
        rejected_shares: 0,
        stale_shares: 0,
        invalid_shares: 0,
      })

module ModuleStructures

  def module_structure
    OpenStruct.new({
      module: self.class.name,
      name: name,
      addresses: {},
    })
  end

  def root_structure
    RootStructure.new
  end

  # Structure of GPU workers
  def node_structure(*p)
#    MiningNode.new
    OpenStruct.new({
      name:     "",
      address:  "",
      port:     0,
      ip:       "",
      miner:    "",
      user:     "",
      uptime:   0,
      algo:     "",
      coin:     "",
      pool:     "",
      difficulty:     0,
      combined_speed: 0.0,
      total_shares:   0,
      rejected_shares: 0,
      stale_shares:   0,
      invalid_shares: 0,
      power_total:    0,
      revenue:        0.0,
      target:   "",
      time:     Time.now,
      gpu:      {},
      cpu:      cpu_structure,
      system:   {},
    })
  end

  def worker_structure(*p)
    node_structure(*p)
  end  
  def structure(*p)
    node_structure(*p)
  end  


  # Structure of GPU data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_structure(*p)
#    MiningGpu.new
    OpenStruct.new({
      pci: "0",
      id: 0,
      gpu_speed: 0.0,
      gpu_temp: 0,
      gpu_fan: 0,
      gpu_power: 0,
      speed_unit: "",
      total_shares: 0,
      rejected_shares: 0,
      stale_shares: 0,
      invalid_shares: 0,
    })
  end

  # Structure of GPU device data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_device_structure(*p)
    OpenStruct.new({
      pci:        "0",
      id:         0,
      card:       "",
      gpu_temp:   0,
      gpu_fan:    0,
      gpu_power:  0,
      core_clock: 0,
      memory_clock: 0,
    })
  end

  def cpu_structure(*p)
    OpenStruct.new({
      :name       =>"",
      :id         =>0,
      :cpu_temp   =>0,
      :cpu_fan    =>0,
      :cpu_power  =>0,
      :threads =>0,
      :threads_used =>0,
      :cores =>0,
    })
  end


end