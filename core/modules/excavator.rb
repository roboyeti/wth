# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class Excavator < GpuBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "Excavator"    
  end

  def check(ip,name)
    host,port = ip.split(':')
    port = port ? port : @port    
    res  = simple_rest("http://#{host}:#{port}/api?command={%22id%22:1,%22method%22:%22algorithm.list%22,%22params%22:[]}")
    res2 = simple_rest("http://#{host}:#{port}/api?command={%22id%22:1,%22method%22:%22worker.list%22,%22params%22:[]}")
    res3 = simple_rest("http://#{host}:#{port}/api?command={%22id%22:1,%22method%22:%22devices.get%22,%22params%22:[]}")
    format(name,ip,res,res2,res3)
  end

  def format(name,ip,algos,workers,devices)
    base = algos["algorithms"][0]
    time = base["uptime"].to_f
    uptime = uptime_minutes(time)
    #time > (1440 * 60) ? sprintf("%.2fd",(time / (1440 * 60))) : sprintf("%.2fh",(time / (60*60)))

    h = worker_structure
    h.name = name
    h.address = ip
    h.uptime = uptime
    h.miner = "Excavator ETH #{base['name']}"
    h.combined_speed = base["speed"].to_f / 1000000.0
    h.total_shares = base["accepted_shares"].to_i
    h.rejected_shares = base["rejected_shares"].to_i

    device_map = {}
    devices["devices"].each {|d|
      device_map[d["device_id"]] = {
        pci: d["details"]["bus_id"],
        temp: d["gpu_temp"].to_i,
        fan: d["gpu_fan_speed"].to_i,
        power: d["gpu_power_usage"].to_f
      }
      h["power_total"] += d["gpu_power_usage"].to_f
    }
        
    workers["workers"].each {|p|
      alg = p["algorithms"][0]
      device = device_map[p["device_id"]]
      h[:gpu][device[:pci]] = {
        pci: device[:pci],
        id: p["device_id"],
        gpu_speed: alg["speed"].to_f / 1000000.0,
        gpu_temp: device[:temp],
        gpu_fan: device[:fan],
        speed_unit: 'Mh/s',
      }
    }
    h
  end
  
end