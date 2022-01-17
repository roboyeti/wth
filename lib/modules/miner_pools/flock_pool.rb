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
class Modules::FlockPool < Modules::MinerPoolBase
  using IndifferentHash  
  
  API_HOST = "https://flockpool.com/api/v1/wallets/rtm"

  def initialize(p={})
    super
    @title = p[:title] || 'Flock (https://flockpool.com)'
    @coin = 'RTM'
    @headers = ['Address','Status','Coin','Avail $','Avail Amt','Unpaid','Pending','Auto Pay#','Combined Speed','Avg Speed', 'Accepted','Rejected','Stale', 'Workers Up/Dwn']

  end

  def check(empty,addr)
    req1 = [API_HOST,addr].join('/')
    res1 = simple_rest(req1)
    format(addr,res1)
  end
  
  def format(name,res1)
    balance_mod = 100000000
    data = res1
    h = pool_structure
    h.name = name
    h.address = name
    h.private_address = " #{h.address[0..2]} ... #{h.address[-3..-1]} "
    h.available_balance = data["balance"]["paid"].to_f / balance_mod
    h.pending_balance = data["balance"]["immature"].to_f / balance_mod
    h.unpaid_balance = data["balance"]["mature"].to_f / balance_mod
    h.auto_pay = data["min_payment"].to_i / balance_mod
    h.coin = coin

    data["workers"].each{|w|
      worker = worker_structure
      worker.last_seen = Time.at(w["last_seen_secs"].to_i)
      worker.online = (Time.now - worker.last_seen) < 600
      worker.online == true ? h.workers_up = h.workers_up + 1 : h.workers_down = h.workers_down + 1
      worker.name = w["name"]
      worker.speed = w["hashrate"]["now"].to_f
      worker.avg_speed = w["hashrate"]["avg"].to_f
      worker.accepted	= w["shares"]["accepted"].to_i
      worker.stale	= w["shares"]["stale"].to_i
      worker.rejected	= w["shares"]["rejected"].to_i
      h.speed = h.speed + worker.speed
      h.avg_speed = h.avg_speed + worker.avg_speed        
      h.accepted = h.accepted + worker.accepted        
      h.stale = h.stale + worker.stale        
      h.rejected = h.rejected + worker.rejected        
      h.workers << worker
    }
    h
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      worker_str = colorize_workers(item)
      speed_str = colorize_speed_compare(item.avg_speed.round(2),item.speed.round(2))
      stale_str = colorize_percent_of(item.accepted,item.stale,0.10,0.50)
      reject_str = colorize_percent_of(item.accepted,item.rejected,0.10,0.50)
      
      private_address = " #{item.name[0..2]} ... #{item.name[-3..-1]} "
      rows << [
        colorize(item.private_address,$color_pool_id), item.status,
        item.coin, coin_value_dollars(item.available_balance,@coin), item.available_balance.round(2),
        item.unpaid_balance.round(2), item.pending_balance.round(2),
        item.auto_pay, speed_str, item.avg_speed.round(2), 
        item.accepted, reject_str, stale_str, worker_str
      ]
    end
    tables
  end

end