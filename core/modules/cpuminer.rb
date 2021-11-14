# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class Cpuminer < Base
  using DynamicHash

  def initialize(p={})
    super
    @title = p[:title] || 'Cpuminer'    
  end

  def check(ip,host)
    res = simple_rest(["http://#{ip}:#{@port}",'summary'].join('/'))
    res2 = simple_rest(["http://#{ip}:#{@port}",'threads'].join('/'))
    format(res,res2,host)
  end

  # 
  def format(res,res2,host)
	s = res.split(/\;/)
	summary = {}
    s.each{|r|
	  k,v = r.split(/\=/)
	  summary[k]=r
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
    
    h.pool   = summary["URL"]
    h["difficulty"] = summary["DIFF"].to_i
    h["rate"] = summary["ACCMN"].to_i
    h.total_shares   = summary["ACC"].to_i
    h.rejected_shares= summary["REJ"].to_i
    h.failed_shared  = summary["SOL"]
      
#    h["avg_time"] = res["connection"]["avg_time"].to_f
#    h["avg_time_ms"] = res["connection"]["avg_time_ms"].to_f   
#    h["hashes_total"] = res["connection"]["hashes_total"].to_i
    h.uptime = summary["UPTIME"]
    h.cpu = cpu_structure
#    h.cpu.name = cpu_clean(res["cpu"]["brand"])
    h.cpu.threads_used = threads.count
puts h
exit
    h
  end

  def console_out(data)
    hash = data[:addresses]
    rows = []
    
    headers = [
      nice_title, "Uptime","Diff","Accpt","Rjct","Fail",
      "Avg H/s","Max H/s","Total KH","Pool","Th#","CPU"
    ]

    hash.keys.sort.map{|addr|
      h = hash[addr]
      if h["down"] == true
        @events << sprintf("%15s - %s",addr,h["message"])
        next
      end

      uptime = uptime_seconds(h["uptime"])

      rows << [
        h.name, uptime,
        h["difficulty"], h.total_shares,h.rejected_shares,h.failed_shared,
        h.combined_speed, '', '',
        h.pool, h.cpu.threads_used, ''
      ]
        #h["hashrate_max"],h["hashes_total"]/1000.0,
        #h.cpu.name
    }
    table_out(headers,rows)
  end
end