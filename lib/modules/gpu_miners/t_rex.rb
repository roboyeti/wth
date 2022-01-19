# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class Modules::TRexMiner < Modules::GpuMinerBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "T-Rex"    
  end

  def check(target,name)
    host,port = target.split(':')
    port = port ? port : @port    
    res = simple_rest("http://#{host}:#{port}/summary")
    format(name,target,res)
  end

  def format(name,ip,res)
    time = res["uptime"].to_f
    uptime = uptime_seconds(time)
    h = node_structure
    h.name = name
    h.address = ip
    h.miner = 'T-Rex'
    h.uptime = uptime
    h.combined_speed = res["hashrate"].to_f / 1000000.0
    h.total_shares = res["accepted_count"].to_i
    h.rejected_shares = res["rejected_count"].to_i
    h.coin = coin
    h.revenue = mine_revenue(h.coin,h.combined_speed).to_f

    device_map = {}
    res["gpus"].each {|d|
      gpu = gpu_structure
      gpu.pci = d["pci_bus"]
      gpu.id = d["device_id"]
      gpu.speed = d["hashrate"].to_f / 1000000.0
      gpu.temp = d["temperature"].to_i
      gpu.fan = d["fan_speed"].to_i
      gpu.power = d["power"].to_f
      gpu.speed_unit = 'Mh/s'
      h.power_total += d["power"].to_f
      h.gpu[gpu.pci] = gpu
    }
    h
  end

end