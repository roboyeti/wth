# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'socket'

class Claymore < GpuBase
  using DynamicHash
 
  def initialize(p={})
    super
    @title = p[:title] || 'Claymore'    
  end

  def check(ip,name)
    host,port = ip.split(':')
    port = port ? port : @port     
    s = Socket.tcp(host, port, connect_timeout: 5)
#    s.puts '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}'
    s.puts '{"id":0,"jsonrpc":"2.0","method":"miner_getstat2"}'
    res = JSON.parse(s.gets)
    begin
      s.closed
    rescue => e
    end
    format(name,res)
  end

  def format(name,res)
    base = res["result"]
    group = base[2].split(';')
    pci = base[15].split(';')    
    speed = base[3].split(';')
    stats = base[6].split(';')    
    shares = base[9].split(';')
    uptime = uptime_minutes(base[1].to_f)
  
    o = worker_structure
    o.name = name
    o.address = name
#    o.miner = base[0].split(' - ')[0]
#    o.miner_coin base[0].split(' - ')[1]
    o.uptime = uptime
    o.pool = base[7]
    o.combined_speed = group[0].to_f / 1000.0
    o.total_shares = group[1].to_i
    o.rejected_shares = group[2].to_i
    o.invalid_shares = base[8].split(';')[0]
    o.power_total = base[17]
    o.gpu = {}

    pci.each_with_index {|p,i|
      g = o.gpu[p] = gpu_structure
      g.pci = p
      g.id = i
      g.gpu_speed = speed[i].to_f / 1000.0
      g.gpu_temp = stats[i*2].to_i
      g.gpu_fan = stats[i*2+1].to_i
      g.speed_unit = 'Mh/s'
    }
    o
  end
  
end