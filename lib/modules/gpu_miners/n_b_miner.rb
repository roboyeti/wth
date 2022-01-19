# Author: BeRogue01
# License: See LICENSE file
# Date: 2021/01
#
class Modules::NBMiner < Modules::GpuMinerBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "NBMiner"
    @port = @config["port"] || "22333"
  end

  def check(addr,host)
    h = cm_node_structure(host,addr)

    res = simple_rest("http://#{h.ip}:#{h.port}/api/v1/status")

    h.miner = "nbminer"
    h.version = res['version']
    h.user = res["stratum"]['user']
    h.uptime = uptime_from_eseconds(res["start_time"].to_i)
    h.algo = res["stratum"]["algorithm"]
    h.pool = res["stratum"]["url"]
    h.total_shares = res["stratum"]["accepted_shares"].to_i
    h.invalid_shares = res["stratum"]["invalid_shares"].to_i
    h.rejected_shares = res["stratum"]["rejected_shares"].to_i
    h.power_total = res["miner"]["total_power_consume"].to_f
    h.combined_speed = res["miner"]["total_hashrate"].split(" ")[0].to_f
    h.coin = coin

    res["miner"]["devices"].each {|d|
      gpu = gpu_structure
      gpu.pci = d["pci_bus_id"].to_i
      gpu.id = d["id"]
      gpu.speed = d["hashrate"].to_f
      gpu.temp = d["temperature"].to_i
      gpu.fan = d["fan"].to_i
      gpu.power = d["power"].to_f
      gpu.speed_unit = 'Mh/s'
      gpu.total_shares = d["accepted_shares"].to_i
#      gpu.stale_shares = d[""].to_i
      gpu.rejected_shares = d["rejected_shares"].to_i
      gpu.invalid_shares = d["invalid_shares"].to_i
      h.gpu[gpu.pci] = gpu
    }
    h.estimated_revenue = calc_estimated_revenue(h)
    h
  end
end