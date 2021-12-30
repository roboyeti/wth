# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class Modules::LolMiner < Modules::GpuMinerBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "LolMiner"
    @port = @config["port"] || 9095
  end

  def check(ip,name)
    host,port = ip.split(':')
    port = port ? port : @port    
    res = simple_rest("http://#{host}:#{port}")
    format(name,ip,res)
  end

  def format(name,ip,res)
    time = res["Session"]["Uptime"].to_f
    uptime = uptime_seconds(time)
    h = node_structure
    h.name = name
    h.address = ip

    h.miner = res['Software']
    h.user = res["Stratum"]['Current_User']
    h.uptime = uptime
    h.algo = res["Mining"]["Algorithm"]
    h.pool = res["Stratum"]["Current_Pool"]
    h.combined_speed = res["Session"]["Performance_Summary"].to_f
    h.total_shares = res["Session"]["Accepted"].to_i
    h.stale_shares = res["Session"]["Stale"].to_i
    h.rejected_shares = res["Session"]["Submitted"].to_i - h.total_shares
    h.invalid_shares = 0
    h.power_total = res["Session"]["TotalPower"].to_f
    h.coin = coin

    res["GPUs"].each {|d|
      gpu = gpu_structure
      gpu.pci = d["PCIE_Address"].split(':')[0].to_i
      gpu.id = d["Index"]
      gpu.gpu_speed = d["Performance"].to_f
      gpu.gpu_temp = d["Temp (deg C)"].to_i
      gpu.gpu_fan = d["Fan Speed (%)"].to_i
      gpu.gpu_power = d["Consumption (W)"].to_f
      gpu.speed_unit = 'Mh/s'
      gpu.total_shares = d["Session_Accepted"].to_i
      gpu.stale_shares = d["Session_Stale"].to_i
      gpu.rejected_shares = d["Session_Submitted"].to_i - gpu.total_shares
      gpu.invalid_shares = 0
      h.gpu[gpu.pci] = gpu
    }
    h.revenue = mine_revenue(h.coin,h.combined_speed).to_f
    h
  end

end