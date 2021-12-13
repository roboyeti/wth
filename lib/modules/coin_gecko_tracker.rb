# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'coingecko_ruby'
require 'lightly'
require 'concurrent'

class CoinGeckoTracker < Base
  using IndifferentHash  

  attr_reader :cache

  def initialize(p={})
    super
    @title = @config["title"] || "CoinGecko"
    @client = CoingeckoRuby::Client.new
    @lifespan = @config["lifespan"] || 120
    @lifespan = 60 if @lifespan < 120
    @currency = @config["currency"] || 'usd'
    @round = @config["round"] || 8
    @profit_round = @config["profit_round"] || 2
  #	@lifespan += rand(0..30)
    @lifeinc = 0
    @cache = {}
  end

  def check(data,name)
    (own,paid) = data.split('::')
    key = "#{name}_#{@currency}"
    @cache[key] = Lightly.new dir: 'tmp/wtm_cache', life: @lifespan + @lifeinc, hash: false
    @lifeinc += 1
    res = @cache[key].get "coingecko_#{key}" do

	  # Really needs to be a checks within sliding window that
	  # utilizes thread safe class variables to ensure they all stay
	  # below free threshold and return gracefully without a down
	  #
	  if @lifeinc > 60
  		sleep(1)
	  elsif @lifeinc > 45
  		sleep(0.5)
	  elsif @lifeinc > 30
  		sleep(0.25)
	  end
	  r = @client.markets(name, vs_currency: @currency)
	  r.each{|c|
  		c["cached_time"] = Time.now
	  }
	  r
	end

    format(name,data,res)
  end

  def format(name,data,res)
    (own,paid,rnd) = data.split('::')
    rnd = @round if !rnd 
    res = res[0]

    h = structure
    h.round = rnd
    h.currency = @currency
    h.holding = own.to_f
    h.cost = paid.to_f
  
    h.id = name
    h.symbol = res["symbol"]
    h.name = res["name"]
    h.price = res["current_price"].to_f
    h.market_cap = res["market_cap"].to_i
    h.market_rank = res["market_cap_rank"].to_i
    h.total_volume = res["total_volume"].to_f
    h.high_24h = res["high_24h"].to_f
    h.low_24h = res["low_24h"].to_f
    h.price_change_24h = res["price_change_24h"].to_f
    h.price_change_percent_24h = res["price_change_percentage_24h"].to_f
    h.circulating_supply = res["circulating_supply"].to_i
    h.total_supply = res["total_supply"].to_i
    h.last_updated = nice_time( parse_rfc3339(res["last_updated"]) )
    h.cached_time = nice_time( res["cached_time"] )
    h
  end

  def structure
    OpenStruct.new({
      id:		"",
      symbol:	"",
      name:		"",
      time:		Time.now,
      currency: "",
      price:	0.0,
      holding: 0.0,
      cost: 0.0,
      market_cap:		0,
      market_rank:		0,
      total_volume:		0,
      high_24h:			0,
      low_24h:			0,
      price_change_24h:	0.0,
      price_change_percent_24h:	0.0,
      circulating_supply:		0.0,
      total_supply:		0.0,
      last_updated:		"",
      cached_time: 		"",
      round: 8,
    })
  end
  
  def console_out(data)
    hash = data[:addresses]
    rows = []
    title = "Coin Portfolio: https://www.coingecko.com : Last checked #{data[:last_check_ago].ceil(2)} seconds ago"
    headers = ['Name','Rank','Price','24h∆%','24h Hgh','24h Low','Hodl','Avg Cost','Value','Profit','   ','Last Updated'] #,'Cached Time']

    total_value = 0.0
    total_profit = 0.0
	
    hash.keys.sort.each_with_index{|addr,i|
      h = hash[addr]
  
      if h.down == true
        h.status = colorize("down",$color_alert)
      else
        h.status = h.market_rank
      end
  
      value = (h.price * h.holding)
      total_value += value
      profit = (value - (h.holding * h.cost)).round(@round)
      total_profit += profit
  
      c = colorizer((i % 2) == 0 ? $color_row_odd : $color_row_even)

      price = sprintf("%.#{h.round}f #{h.currency.upcase}",h.price)
      high_24h = sprintf("%.#{h.round}f #{h.currency.upcase}",h.high_24h)
      low_24h = sprintf("%.#{h.round}f #{h.currency.upcase}",h.low_24h)

      rows << [
        c.call("#{h.name} (#{h.symbol.upcase})"),
        c.call(h.status),
        c.call(price),
        colorize_around(h.price_change_percent_24h.round(2),0,2) ,
        c.call(high_24h), c.call(low_24h),
        c.call(h.holding), c.call(h.cost), c.call(sprintf("%.#{@profit_round}f",value)), colorize_around(profit,0,@profit_round),
        ' ',c.call(h.last_updated) #,c.call(h.cached_time)
      ]
    }
  
    c = colorizer(total_profit >= 0 ? :bright_green : :bright_red)
  
    rows << headers.map{|m| ' ' }
    rows << [
      c.call("Total"),"","","","","","","",c.call(total_value.round(@profit_round)),colorize_around(total_profit.round(@profit_round),0,@profit_round),' ',' '#,' '
    ]

    table_out(headers,rows,title)
  end

  
#=> [{
#"id"=>"bitcoin",
#  "symbol"=>"btc",
#  "name"=>"Bitcoin",
#  "image"=>"https://assets.coingecko.com/coins/images/1/large/bitcoin.png?1547033579",
#  "current_price"=>36172,
#  "market_cap"=>683564917837,
#  "market_cap_rank"=>1,
#  "fully_diluted_valuation"=>759602744067,
#  "total_volume"=>23748239978,
#  "high_24h"=>37895,
#  "low_24h"=>35438,
#  "price_change_24h"=>-149.932746949031,
#  "price_change_percentage_24h"=>-0.41279,
#  "market_cap_change_24h"=>-2797994006.838745,
#  "market_cap_change_percentage_24h"=>-0.40766,
#  "circulating_supply"=>18897856.0,
#  "total_supply"=>21000000.0,
#  "max_supply"=>21000000.0,
#  "ath"=>51032,
#  "ath_change_percentage"=>-29.1696,
#  "ath_date"=>"2021-11-10T14:24:11.849Z",
#  "atl"=>43.9,
#  "atl_change_percentage"=>82233.43135,
#  "atl_date"=>"2013-07-05T00:00:00.000Z",
#  "roi"=>nil,
#  "last_updated"=>"2021-12-11T07:48:54.475Z"}]

end