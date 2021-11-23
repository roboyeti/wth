# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class TRex < GpuBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "TRex"    
  end

  def check(ip,name)
    host,port = ip.split(':')
    port = port ? port : @port    
    res = simple_rest("http://#{host}:#{port}/summary")
    format(name,res)
  end

  def format(name,res)
    time = res["uptime"].to_f
    uptime = uptime_seconds(time)
 
    hash = {
      name: name,
      address: name,
      miner: "",
      uptime: uptime,
      combined_speed: res["hashrate"].to_f / 1000000.0,
      total_shares: res["accepted_count"].to_i,
      rejected_shares: res["rejected_count"].to_i,
      gpu: {},
    }
 
    hash["power_total"] = 0
    
    device_map = {}
    res["gpus"].each {|d|
      device_map[d["device_id"]] = {
        pci: d["pci_bus"],
        temp: d["temperature"].to_i,
        fan: d["fan_speed"].to_i,
        power: d["power"].to_f
      }
      hash["power_total"] += d["power_avr"].to_f
    }
        
    res["gpus"].each {|p|
      device = device_map[p["device_id"]]
      hash[:gpu][device[:pci]] = {
        pci: device[:pci],
        id: p["device_id"],
        gpu_speed: p["hashrate"].to_f / 1000000.0,
        gpu_temp: device[:temp],
        gpu_fan: device[:fan],
        speed_unit: 'Mh/s',
      }
    }
    hash
  end

end