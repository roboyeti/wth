# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class Xmrig < Base
  using IndifferentHash  

  def initialize(p={})
    super
    @title = p[:title] || 'XMRig RandX'    
  end

  def check(ip,host)
    res = simple_rest(["http://#{ip}:#{@port}",'1','summary'].join('/'))
    format(res)
  end

  def format(res)
    h = worker_structure
    h.address = res["id"]
    h.name = res["worker_id"] || res["id"]
    h.uptime = res["uptime"]
    h.pool   = res["connection"]["pool"]
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

    h.cpu = cpu_structure
    h.cpu.name = cpu_clean(res["cpu"]["brand"])
    h.cpu.threads_used = res["hashrate"]["threads"].count
    h
  end

  def console_out(data)
    hash = data[:addresses]
    rows = []
    
    headers = [
      nice_title, "Uptime","Diff","Accpt","Rjct","Fail",
      "Avg H/s","Max H/s","Total KH","Pool","Th#","CPU"
    ]
    uptime = colorize("down",$color_alert)

    hash.keys.sort.map{|addr|
      h = hash[addr]
      if h.down == true
        h.cpu = cpu_structure
      else
        uptime = uptime_seconds(h.uptime)
      end
      
      rows << [
        h.name, uptime,
        h.difficulty, h.total_shares,h.rejected_shares,h.failed_shared,
        h.combined_speed, h.max_speed, h.hashes_total/1000.0,
        h.pool, h.cpu.threads_used, h.cpu.name
      ]
    }
    table_out(headers,rows)
  end

  def node_structure
    struct = super
    struct.hashes_total = 0
    struct.max_speed = 0
    struct.hashrate_10s = 0
    struct.hashrate_60s = 0
    struct.hashrate_15m = 0
    struct.max_speed = 0
    struct
  end
end