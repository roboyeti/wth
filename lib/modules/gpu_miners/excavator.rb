# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# nhqm.conf:
# "watchDogAPIAuth" : "your_private_api_key",
#	"watchDogAPIHost" : "0.0.0.0",
#	"watchDogAPIPort" : 18000,
#	"watchDogAPITimeout" : 2000,
#

class Modules::Excavator < Modules::GpuMinerBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "Excavator"
    @port = @config[:port] || 18000
  end

  def check(addr,host)
    h = cm_node_structure(host,addr)

    algo  = simple_rest("http://#{h.ip}:#{h.port}/api?command={%22id%22:1,%22method%22:%22algorithm.list%22,%22params%22:[]}")
    workers = simple_rest("http://#{h.ip}:#{h.port}/api?command={%22id%22:1,%22method%22:%22worker.list%22,%22params%22:[]}")
    devices = simple_rest("http://#{h.ip}:#{h.port}/api?command={%22id%22:1,%22method%22:%22devices.get%22,%22params%22:[]}")
    info = simple_rest("http://#{h.ip}:#{h.port}/api?command={%22id%22:1,%22method%22:%22info%22,%22params%22:[]}")

    base = algo["algorithms"][0]
    fail "Error in response from #{@title}." if base.blank?
    h.uptime = uptime_minutes(base["uptime"].to_f)
    h.miner = "nhqm_excavator"
    h.version = info["version"]
    h.algo = base["name"]
    h.pool = 'nicehash'
    h.combined_speed = base["speed"].to_f / 1000000.0
    h.total_shares = base["accepted_shares"].to_i
    h.rejected_shares = base["rejected_shares"].to_i
    h.coin = coin
    h.revenue = mine_revenue(h.coin,h.combined_speed).to_f

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
        speed: alg["speed"].to_f / 1000000.0,
        temp: device[:temp],
        fan: device[:fan],
        power: device[:power],
        speed_unit: 'Mh/s',
      }
    }

    h
  end
  
end