# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class Modules::NanoMiner < Modules::GpuMinerBase
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || "NanoMiner"
    @port = @config["port"] || 9090
  end

  def check(ip,name)
    host,port,algo = ip.split(':')
    port = port && !port.empty? ? port : @port    
    res = simple_rest("http://#{host}:#{port}/stats")
    format(name,ip,res)
  end

  def format(name,ip,res)
    host,port,algo = ip.split(':')
    algo = algo.downcase.capitalize

    alg = res["Algorithms"][0][algo]
    devices = res["Devices"][0]

    h = node_structure
    h.name = name
    h.address = "#{host}:#{port}"

    time = res["WorkTime"].to_f
    uptime = uptime_seconds(time)
    h.uptime = uptime

    h.miner = title
    h.algo = algo
    h.pool = alg["CurrentPool"]
    h.coin = coin
    h.combined_speed = alg["Total"]["Hashrate"].to_f / 1000000.0
    h.total_shares = alg["Total"]["Accepted"].to_i
    h.rejected_shares = alg["Total"]["Denied"].to_i
    devices.each_key {|k|
      d = devices[k]
      d2 = alg[k]
      gpu = gpu_structure
      gpu.pci = d["Pci"].split(':')[0].to_i
      gpu.id = k.split(' ')[1]
      gpu.gpu_speed = d2["Hashrate"].to_f / 1000000.0
      gpu.gpu_temp = d["Temperature"].to_i
      gpu.gpu_fan = d["Fan"].to_i
      gpu.gpu_power = d["Power"].to_f
      gpu.speed_unit = 'Mh/s'
      gpu.total_shares = d2["Accepted"].to_i
      gpu.rejected_shares = d2["Denied"].to_i
      h.power_total += gpu.gpu_power
      h.gpu[gpu.pci] = gpu
    }
    h.revenue = mine_revenue(h.coin,h.combined_speed).to_f
    h
  end

end

#{
#  "Algorithms": [
#    {
#      "Ethash": {
#        "CurrentPool": "ethash.unmineable.com:3333",
#        "GPU 0": {
#          "Accepted": 0,
#          "Denied": 0,
#          "Hashrate": "3.490708e+07"
#        },
#        "ReconnectionCount": 0,
#        "Total": {
#          "Accepted": 0,
#          "Denied": 0,
#          "Hashrate": "3.490708e+07"
#        }
#      }
#    }
#  ],
#  "Devices": [
#    {
#      "GPU 0": {
#        "Name": "NVIDIA GeForce RTX 2060 SUPER",
#        "Platform": "CUDA",
#        "Pci": "09:00.0",
#        "Fan": 74,
#        "Temperature": 54,
#        "Power": 88.5
#      }
#    }
#  ],
#  "WorkTime": 20
#}