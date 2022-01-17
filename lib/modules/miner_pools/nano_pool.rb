# Author: BeRogue01
# License: See LICENSE file
# Date: 2022/01
#
# https://api.nanopool.org/v1/eth/user/:address
# 
#
class Modules::NanoPool < Modules::MinerPoolBase
  using IndifferentHash  
  
  API_HOST = "https://api.nanopool.org/v1"

  def initialize(p={})
    super
    @title = p[:title] || 'Nano (https://nanopool.org)'
    @coin = 'ETH'
    @headers = [
'Address','Status','Coin','Avail $',
#'Avail Amt',
'Unpaid','Pending',
#'Auto Pay#',
'Combined Speed','Avg Speed',
#'Accepted','Rejected','Stale',
'Workers Up/Dwn']

  end

  def check(opts,name)
    addr,coin = opts.split(':')

    data = simple_rest("https://api.nanopool.org/v1/#{coin.downcase}/user/#{addr}")["data"]
logger.info(data)  
#    balance_mod = 100000000
    h = pool_structure
    h.name = name #data["account"]
    h.address = data["account"]
    h.private_address = " #{h.address[0..3]}...#{h.address[-3..-1]} "
#    h.available_balance = data["balance"].to_f
    h.pending_balance = data["unconfirmed_balance"].to_f
    h.unpaid_balance = data["balance"].to_f
#    h.auto_pay = data["min_payment"].to_i / balance_mod
    h.coin = coin
    h.speed = data["hashrate"].to_f

    data["workers"].each{|w|
      worker = worker_structure
      worker.last_seen = Time.at(w["lastshare"].to_i)
      worker.online = (Time.now - worker.last_seen) < 600
      worker.online == true ? h.workers_up = h.workers_up + 1 : h.workers_down = h.workers_down + 1
      worker.name = w["id"]
      worker.speed = w["hashrate"].to_f
      worker.avg_speed = w["h1"].to_f
#      worker.accepted	= w["shares"]["accepted"].to_i
#      worker.stale	= w["shares"]["stale"].to_i
#      worker.rejected	= w["shares"]["rejected"].to_i
      h.avg_speed = h.avg_speed + worker.avg_speed        
#      h.accepted = h.accepted + worker.accepted        
#      h.stale = h.stale + worker.stale        
#      h.rejected = h.rejected + worker.rejected        
      h.workers << worker
    }
    h
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      worker_str = colorize_workers(item)
      speed_str = colorize_speed_compare(item.avg_speed.round(2),item.speed.round(2))
#      stale_str = colorize_percent_of(item.accepted,item.stale,0.10,0.50)
#      reject_str = colorize_percent_of(item.accepted,item.rejected,0.10,0.50)
      
      rows << [
        colorize(item.private_address,$color_pool_id), item.status,
        item.coin, coin_value_dollars(item.unpaid_balance,@coin), #item.available_balance.round(2),
        sprintf("%0.8f",item.unpaid_balance.round(8)),
        sprintf("%0.8f",item.pending_balance.round(8)),
#        item.auto_pay,
        speed_str, item.avg_speed.round(2), 
#        item.accepted, reject_str, stale_str,
        worker_str
      ]
    end
    tables
  end

end