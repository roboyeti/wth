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
require 'socket'

class Cpuminer < Base
  using IndifferentHash  

  VERSION = "1.2.4.1"
  URL = "https://github.com/WyvernTKC/cpuminer-gr-avx2/releases"

  CMDS = {
    'summary': '/summary',
    'threads': '/threads'
  }
  
  def initialize(p={})
    super
    @title = p[:title] || 'Cpuminer'    
  end

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
		(ip,port) = addr.split(':')
		port = port ? port : @port 
    @responses["#{host}:#{port}"] = {}

    CMDS.each_pair{|k,v|
  		@responses["#{host}:#{port}"]["#{k}"] = send_command(ip,port,v)
    }
		format(host,@responses["#{host}:#{port}"])
  end

  # 
  def format(host,responses)
    res = responses["summary"]
    res2 = responses["threads"]

		s = res.split(/\;/)
		summary = {}
			s.each{|r|
			k,v = r.split(/\=/)
			summary[k]=v
		}
	
		threads = []
		t = res2.split(/\|/)
		t.each{|r|
			threads << r.split(/\=/)[1]
		}
	
    h = worker_structure
    h.address = host
    h.name = host
    h.combined_speed = h["hashrate"] = summary["HS"]
    h.algo = summary['ALGO']    
    h.pool   = summary["URL"]
    h["difficulty"] = summary["DIFF"].to_f.round(4)
    h["rate"] = summary["ACCMN"].to_f.round(4)
    h.total_shares   = summary["ACC"].to_i
    h.rejected_shares= summary["REJ"].to_i
    h.failed_shared  = summary["SOL"]
      
    h.uptime = summary["UPTIME"].to_i
    h.cpu = cpu_structure
#    h.cpu.name = cpu_clean(res["cpu"]["brand"])
    h.cpu.threads_used = summary["CPUS"].to_i
#puts h
#exit
    h
  end

  def console_out(data)
    hash = data[:addresses]
    rows = []
    
    headers = [
      nice_title, "Uptime","Algo","Diff","Accpt","Rjct","Sol?",
      "Avg H/s","Accept/Min","Pool","Th#","CPU"
    ]
    hash.keys.sort.map{|addr|
      h = hash[addr]
      uptime = "down"
      if h["down"] == true
        n = worker_structure
        n.name = addr
        n.uptime = colorize("down",$color_alert)
        n.combined_speed = 0
        @events << $pastel.red(sprintf("%s : %22s: %s",Time.now,addr,h["message"]))
        n.cpu = cpu_structure
        h = n
      else
        uptime = uptime_seconds(h.uptime) if h.uptime != "down"
      end
      
      rows << [
        h.name, uptime, h.algo,
        h["difficulty"], h.total_shares,h.rejected_shares,h.failed_shared,
        h.combined_speed, h.rate,
        h.pool, h.cpu.threads_used, ''
      ]
        #h["hashrate_max"],h["hashes_total"]/1000.0,
        #h.cpu.name
    }
    table_out(headers,rows)
  end
end