# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'socket'

class Cpuminer < Base
  using DynamicHash

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
      
#    h["hashrate_60s"] = res["hashrate"]["total"][1].to_f || 0.0
#    h["avg_time"] = res["connection"]["avg_time"].to_f
#    h["avg_time_ms"] = res["connection"]["avg_time_ms"].to_f   
#    h["hashes_total"] = res["connection"]["hashes_total"].to_i
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
      nice_title, "Uptime","Algo","Diff","Accpt","Rjct","Fail",
      "Avg H/s","Pool","Th#","CPU"
    ]
#"Max H/s","Total KH",
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
        h.combined_speed,
        h.pool, h.cpu.threads_used, ''
      ]
        #h["hashrate_max"],h["hashes_total"]/1000.0,
        #h.cpu.name
    }
    table_out(headers,rows)
  end
end