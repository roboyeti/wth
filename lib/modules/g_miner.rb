# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class GMiner < GpuBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "GMiner"
    @port = @config["port"] || 10555
  end

  def check(ip,name)
    host,port = ip.split(':')
    port = port ? port : @port    
    res = simple_rest("http://#{host}:#{port}/stat")
    format(name,ip,res)
  end

  def format(name,ip,res)
    time = res["uptime"].to_f
    uptime = uptime_seconds(time)
    h = node_structure
    h.name = name
    h.address = ip
    h.miner = res['miner']
    h.uptime = uptime
    h.pool = res["server"]
    h.algo = res["algorithm"]
    h.pool_speed = res["pool_speed"].to_f / 1000000.0
    h.total_shares = res["total_accepted_shares"].to_i
    h.rejected_shares = res["total_rejected_shares"].to_i
    h.stale_shares = res["total_stale_shares"].to_i
    h.invalid_shares = res["total_invalid_shares"].to_i
    h.coin = coin

    res["devices"].each {|d|
      gpu = gpu_structure
#bus_id	"0000:09:00.0"
#name	"2060S"
#core_clock	1080
#memory_clock	7400
      gpu.pci = d["bus_id"].split(':')[1].to_i
      gpu.id = d["gpu_id"]
      gpu.gpu_speed = d["speed"].to_f / 1000000.0
      gpu.gpu_temp = d["temperature"].to_i
      gpu.gpu_fan = d["fan"].to_i
      gpu.gpu_power = d["power_usage"].to_f
      gpu.speed_unit = 'Mh/s'
      gpu.total_shares = res["accepted_shares"].to_i
      gpu.rejected_shares = res["rejected_shares"].to_i
      gpu.stale_shares = res["stale_shares"].to_i
      gpu.invalid_shares = res["invalid_shares"].to_i
      h.power_total += d["power_usage"].to_f
      h.combined_speed += (d["speed"].to_f / 1000000.0)
      h.gpu[gpu.pci] = gpu
    }
    h.revenue = mine_revenue(h.coin,h.combined_speed).to_f
    h
  end

end