# Author: BeRogue01
# License: See LICENSE file
# Date: 2022/01
#
# https://api.nanopool.org/v1/eth/user/:address
# 
#
class Modules::TwoMinersPool < Modules::MinerPoolBase
  using IndifferentHash  
  
  API_HOST = "https://eth.2miners.com/api"

  def initialize(p={})
    super
    @title = p[:title] || '2Miners (https://2miners.com)'
    @api_host = @config[:api_node] || API_HOST 
    @coin = @config[:coin] || 'ETH'
    @headers = ['Address','Status','Coin','Paid$','Paid','Unpaid$','Unpaid','Unconfirmed','MinPayout','Calc Speed','Avg Speed','Accepted','Rejected','Stale','Workers Up/Dwn']
  end

  def check(opts,name)
    addr,coin = opts.split(':')
    coin = self.coin if coin.blank?
    data = simple_rest("#{@api_host}/accounts/#{addr}")
    div = 1000000

    h = pool_structure
    h.name = name
    h.address = addr
    h.private_address = private_address(h.address)
    h.available_balance = data["payments"].sum{|p|
      (p["amount"].to_f / 1000000000).round(8)
    }

    h.pending_balance = (data["stats"]["immature"].to_f / 1000000000).round(8)
    h.unpaid_balance = (data["stats"]["balance"].to_f / 1000000000).round(8)
    h.auto_pay = (data["config"]["minPayout"].to_f / 1000000000).round(3)
    h.coin = coin
    h.speed = (data["currentHashrate"].to_f / div).round(1)
    h.avg_speed = (data["hashrate"].to_f / div).round(1)
    h.accepted = data["sharesValid"].to_i
    h.stale = data["sharesStale"].to_i
    h.rejected = data["sharesInvalid"].to_i
    h.paysin = data["config"]["paymentHubHint"]

    h.workers_up = data["workersOnline"].to_i
    h.workers_down = data["workersOffline"].to_i

    data["workers"].each_pair{|k,w|
      worker = worker_structure
      worker.last_seen = Time.at(w["lastBeat"].to_i)
      worker.online = !w["offline"]
      worker.name = w["id"]
      worker.speed = ( w["hr"].to_f / div).round(1)
      worker.avg_speed = ( w["hr2"].to_f / div).round(1)
      worker.accepted	= w["sharesValid"].to_i
      worker.stale = w["sharesStale"].to_i
      worker.rejected = w["sharesInvalid"].to_i
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
      
      rows << [
        colorize(item.private_address,$color_pool_id), item.status,
        item.coin,
        coin_value_dollars(item.available_balance,item.coin),
        item.available_balance.round(4),
        coin_value_dollars(item.unpaid_balance,@coin),
        sprintf("%0.8f",item.unpaid_balance.round(8)),
        sprintf("%0.8f",item.pending_balance.round(8)),
        item.auto_pay,
        speed_str, item.avg_speed.round(2), 
        item.accepted.to_i, reject_str, stale_str,
        worker_str
      ]
    end
    tables
  end

end