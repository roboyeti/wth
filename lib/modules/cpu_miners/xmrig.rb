# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class Modules::Xmrig < Modules::CpuMinerBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = config["title"] || 'XMRig'    
    @headers = [ 'Node', "Uptime", "Miner", 'Algo', 'Coin', 'ERev$', "Accpt","Rjct","Fail", "Avg H/s","Max H/s","Pool","Th#","CPU" ]
  end

  def check(addr,host)
    h = cm_node_structure(host,addr)

    res = simple_rest(["http://#{h.ip}:#{h.port}",'1','summary'].join('/'))

    h.name = res["worker_id"] || host
    h.uptime = res["uptime"]
    h.pool   = res["connection"]["pool"]
    h.algo = res["algo"]
    h.miner = "xmrig_#{res["version"]}"

    h.difficulty = res["connection"]["diff"].to_i
    h.total_shares   = res["connection"]["accepted"].to_i
    h.rejected_shares= res["connection"]["rejected"].to_i
    h.failed_shared  = res["connection"]["failures"]
      
    h.hashrate_10s = res["hashrate"]["total"][0].to_f || 0.0
    h.hashrate_60s = res["hashrate"]["total"][1].to_f || 0.0
    h.hashrate_15m = res["hashrate"]["total"][2].to_f || 0.0
    h.max_speed = res["hashrate"]["highest"].to_f|| 0.0
    h.hashes_total = res["connection"]["hashes_total"].to_i
    
    h.combined_speed = if h.hashrate_15m > 0
      h.hashrate_15m
    elsif h.hashrate_60s > 0
      h.hashrate_60s
    else
      h.hashrate_10s
    end
    h.estimated_revenue = calc_estimated_revenue(h)

    h.cpu.name = cpu_clean(res["cpu"]["brand"])
    h.cpu.threads_used = res["hashrate"]["threads"].count
    h.cpu.cores = res["cpu"]["cores"]
    h.cpu.threads = res["cpu"]["threads"]
    h
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      rows << [
        item.name.capitalize, uptime_seconds(item.uptime), item.miner,
        item.algo, item.coin, item.estimated_revenue,
        item.total_shares,item.rejected_shares,item.failed_shared,
        item.combined_speed, item.max_speed,
        item.pool.split(':')[0], "#{item.cpu.threads_used}/#{item.cpu.threads}", item.cpu.name
      ]
    end
    tables
  end

  def cm_node_structure(host,addr)
    node = super(host,addr)
    node.hashes_total = 0
    node.max_speed = 0
    node.hashrate_10s = 0
    node.hashrate_60s = 0
    node.hashrate_15m = 0
    node
  end
end