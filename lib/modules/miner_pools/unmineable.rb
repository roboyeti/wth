# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# https://api.unminable.com/v4/address/0xBC31664a2200643Bc0C7884E8c59531B1e0B2c1d?coin=etc
# https://api.unminable.com/v4/account/88577ee8-2d8d-433b-ae44-2a4da69c155d/workers
# https://api.unminable.com/v4/account/88577ee8-2d8d-433b-ae44-2a4da69c155d/stats
#
class Modules::Unmineable < Modules::MinerPoolBase
  using IndifferentHash  
  
  API_HOST = "https://api.unminable.com/v4"

  def initialize(p={})
    super
    @title = p[:title] || 'Unmineable'
    @threads = {}
    @headers = ['Address','Status','Coin','$ Avail','Balance','Pay Min','Network','Algo','Fee%','Auto Pay','Combined Speed','Calculated Speed', 'Workers Up/Dwn']
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
    h.mining_fee = data["mining_fee"].to_f
    h.enabled = data["enabled"] || false
    h.auto_pay = data["auto"] || false
    h.network = data["network"]
    h.payout_minimum = data["payment_threshold"].to_f
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

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      worker_str = colorize_workers(item)
      calc_str = colorize_speed_compare(item.speed.round,item.calc_speed.round)
      mining_fee = colorize_simple_threshold(item.mining_fee,">",0.5,0.75)
      balance = colorize_simple_threshold(item.available_balance,"<",item.payout_minimum,item.payout_minimum/2)

      rows << [
        colorize(item.private_address,$color_pool_id), item.status,
        item.coin, coin_value_dollars(item.available_balance.to_f, item.coin), balance, item.payout_minimum,
        item.network, item.algo, mining_fee, item.auto_pay,
        item.speed.round,calc_str, worker_str
      ]
    end
    tables
  end
end