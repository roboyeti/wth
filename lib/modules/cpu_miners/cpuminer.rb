# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# http://192.168.0.113:4048/summary
# NAME=cpuminer-opt-gr;VER=1.2.4.1;API=1.0;ALGO=gr;CPUS=6;URL=/us-west.flockpool.com:5555;HS=266.99;KHS=0.27;ACC=2263;REJ=0;SOL=0;ACCMN=1.180;DIFF=6.465386;TEMP=0.0;FAN=0;FREQ=0;UPTIME=115058;TS=1637223717|
#
# Cpuminer is annoying.  It slams the socket shut on any incorrect input and also sometimes seems to slam it shut
# after a short amount of time.  Worst API so far...
# Due to this, there is an unusual handler around the socket comm.  A minimal request is made, to escape the timing issue
# and a no-op rescue to let the system keep working.  This will have the effect of making the node appear to be down
# until the next check (which is delayed for downed nodes).
#
# Note:  If you are running a hardware monitor, like LibreHardwareMonitor on the nodes running this miner, the cpu
# field should get filled in (via store_get() ), but it may take a round or two
#
require 'socket'

class Modules::Cpuminer < Modules::CpuMinerBase
  using IndifferentHash  

  URL = "https://github.com/WyvernTKC/cpuminer-gr-avx2/releases"

  def initialize(p={})
    super
    @title = p[:title] || 'Cpuminer'    
    @headers = [ 'Node', "Uptime","Ver","Algo","Coin","ERev$","Diff","Accpt","Rjct","Sol","Avg H/s","Accept/Min","Pool","Th#","CPU" ]
  end

  # Sends the totally annoying, 1990 way of communication...?!?!?!
  # This socket is touchy and rude.  Do our best to read from it.
  # Well, maybe not our best, but certainly more than this awful
  # API deserves.
  #
	def send_command(host,port,cmd)
		@socket = Socket.tcp(host, port, connect_timeout: 5)
		@socket.puts %Q[GET #{cmd} HTTP/1.1
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n

]
		line = ""
		while l= @socket.getc
			line << l if l
		end

    begin
  		@socket.close
    rescue => e
    end
		line.chomp!

		return line
  end

  def check(addr,host)
    h = cm_node_structure(host,addr)

    res = send_command(h.ip,h.port,'/summary')
    res2 = send_command(h.ip,h.port,'/threads')
    @dump && dump_response("#{h.ip}_#{h.port}",[res,res2])

		summary = {}
    res.split(/\;/).each{|r|
			k,v = r.split(/\=/)
			summary[k]=v
		}
	
		threads = []
		res2.split(/\|/).each{|r|
			threads << r.split(/\=/)[1]
		}
	
    h.combined_speed = h["hashrate"] = summary["HS"]
    h.algo = summary['ALGO']    
    h.pool   = summary["URL"]
    h.miner = summary["NAME"]
    h.version = summary["VERSION"]
    h.difficulty = summary["DIFF"].to_f.round(4)
    h.accept_rate = summary["ACCMN"].to_f.round(4)
    h.total_shares   = summary["ACC"].to_i
    h.rejected_shares= summary["REJ"].to_i
    h.failed_shared  = summary["SOL"]      
    h.uptime = summary["UPTIME"].to_i
    h.cpu.name = store_get("#{ip}_cpu_name") || ''
    h.cpu.threads_used = summary["CPUS"].to_i
    h.estimated_revenue = calc_estimated_revenue(h)
    h
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      rows << [
        item.name.capitalize, uptime_seconds(item.uptime), item.version,
        item.algo, item.coin, item.estimated_revenue,
        item.difficulty, item.total_shares,item.rejected_shares,item.failed_shared,
        item.combined_speed, item.accept_rate,
        item.pool.split(':')[0], item.cpu.threads_used, item.cpu.name
      ]
    end
    tables
  end

  def cm_node_structure(host,addr)
    struct = super(host,addr)
    struct.hashes_total = 0
    struct.max_speed = 0
    struct.accept_rate = 0
    struct
  end
end