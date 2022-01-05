# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# https://api.unminable.com/v4/address/0xBC31664a2200643Bc0C7884E8c59531B1e0B2c1d?coin=etc
# https://api.unminable.com/v4/account/88577ee8-2d8d-433b-ae44-2a4da69c155d/workers
# https://api.unminable.com/v4/account/88577ee8-2d8d-433b-ae44-2a4da69c155d/stats
require 'rest-client'
require 'json'

class Modules::Unmineable < Modules::MinerPoolBase
  using IndifferentHash  
  
  API_HOST = "https://api.unminable.com/v4"

  def initialize(p={})
    super
    @title = p[:title] || 'Unmineable'
    @threads = {}
  end

  def check(target,type)
    (addr,coin) = target.split(":")

    ckey = "#{addr}_#{coin}"

    ret = if @threads[ckey]
      val = @threads[ckey].value!(0.25)
      if val
        @threads.delete(ckey)
        val
      else
        warn_structure(type,target)
      end
    else
      @threads[ckey] = Concurrent::Promises.future(ckey) do |ckey|
        req1 = [API_HOST,'address',"#{addr}?coin=#{coin}"].join('/')
        res1 = simple_rest(req1)
        uuid = res1["data"]["uuid"]
        req2 = [API_HOST,'account', uuid, 'workers'].join('/')
        res2 = simple_rest(req2)
        format(type,target,res1,res2)
      end
      warn_structure(type,target)
    end
    return ret
  rescue => e
    @threads.delete(ckey)
    raise e
  end

  def warn_structure(type,target)
    h = format(type,target)
    h.status = colorize("pending...",$color_warn)
    h.state = 'pending_update'
    h
  end

  def format(name,target,res1={"data"=>{}},res2={"data"=>{}})
    (addr,coin) = target.split(":")
    data = res1["data"]
    h = pool_structure
    h.name = name
    h.address = addr
    h.private_address = " #{h.address[0..2]} ... #{h.address[-3..-1]} "
    h.available_balance = data["balance_payable"]
    h.uuid = data["uuid"]
    h.mining_fee = data["mining_fee"]
    h.enabled = data["enabled"] || false
    h.auto_pay = data["auto"] || false
    h.network = data["network"]
    h.coin = coin
    errs = 0
    h.errors = data["err_flags"].each_pair{|k,v| err = err + 1 if v} if data["err_flags"]
    algo = []
    res2["data"].each_pair{|ak,av|
      av["workers"].each{|w|
        worker = worker_structure
        algo << ak
        worker.algo = ak
        worker.online = w["online"]
        worker.online ? h.workers_up = h.workers_up + 1 : h.workers_down = h.workers_down + 1
        worker.name = w["name"]
        worker.uptime = w["last"].to_i
        worker.uptime_nice = uptime_seconds(worker.uptime)
        worker.speed = w["rhr"].to_f
        worker.calc_speed = w["chr"].to_f
        h.speed = h.speed + worker.speed
        h.calc_speed = h.calc_speed + worker.calc_speed        
        h.workers << worker
      }
    }
    h.algo = algo.uniq.join(',')
    h
  end

  # TODO: rework to be generic table to be rendered in console or html
  def console_out(data)
    hash = data[:addresses]
    rows = []
    title = "Unmineable : Last checked #{data[:last_check_ago].ceil(2)} seconds ago"
    headers = ['Address','Status','Coin','$ Avail','Balance','Network','Algo','Fee','Auto Pay','Combined Speed','Calculated Speed', 'Workers Up/Dwn']
      
    hash.keys.sort.map{|addr|
      h = hash[addr]

      if h["down"] == true
        h.status = colorize("down",$color_alert)
      end
      
      worker_str = colorize_workers(h)
      calc_str = colorize_speed_compare(h.speed.round,h.calc_speed.round)

      rows << [
        colorize(h.private_address,$color_pool_id), h.status,
        h.coin, coin_value_dollars(h.available_balance.to_f, h.coin), h.available_balance, h.network, h.algo, h.mining_fee, h.auto_pay,
        h.speed.round,calc_str, worker_str
      ]
    }
    table_out(headers,rows,title)
  end

end