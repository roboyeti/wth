# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'socket'

class Cpuminer < Base
  using DynamicHash

  def initialize(p={})
    super
    @title = p[:title] || 'Cpuminer'    
  end

	def send_command(host,port,cmd)
		@socket = TCPSocket.open host, port
		@socket.puts "GET /#{cmd} HTTP/1.1\n"
		@socket.puts "Host: BeRogue\n"
		@socket.puts "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n"
		@socket.puts "\n\n"
		line = ""
		while l= @socket.getc
			line << l if l
		end
		@socket.close
		return line
  end

  def check(addr,host)
		(ip,port) = addr.split(':')
		port = port ? port : @port 
		res = send_command(ip,port,'summary')
		res2 = send_command(ip,port,'threads')
		format(res,res2,host)
  end

  # 
  def format(res,res2,host)
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
#    h["hashrate_60s"] = res["hashrate"]["total"][1].to_f || 0.0
    h.algo = summary['ALGO']    
    h.pool   = summary["URL"]
    h["difficulty"] = summary["DIFF"].to_f.round(4)
    h["rate"] = summary["ACCMN"].to_f.round(4)
    h.total_shares   = summary["ACC"].to_i
    h.rejected_shares= summary["REJ"].to_i
    h.failed_shared  = summary["SOL"]
      
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
      if h["down"] == true
        @events << sprintf("%15s - %s",addr,h["message"])
        next
      end

      uptime = uptime_seconds(h["uptime"])

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