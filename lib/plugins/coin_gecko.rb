# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Portfolio plugin using coingecko.com
#
require 'coingecko_ruby'
require 'lightly'
require 'concurrent'

class CoinGecko < PluginBase
  #using IndifferentHash  

  attr :lifespan
  attr_reader :cache

  def initialize(p={})
    super
    @sema_calc = Concurrent::Semaphore.new(1)
    @sema_coin = Concurrent::Semaphore.new(1)
    @client = CoingeckoRuby::Client.new

    @lifespan = p[:lifespan] || 180
    @coin_cache = Lightly.new dir: 'tmp/coingecko_cache', life: 86400 , hash: false
    @cache = Lightly.new dir: 'tmp/coingecko_cache', life: @lifespan , hash: false
    coin_list # Init cached data storage
  end

  def register
    @registry ||= Sash.new(
      'coin_value_dollars' => 'coin_value_dollars',
      'coin_value_currency' => 'coin_value',
    )
  end
    
  def flush
    @cache.flush
  end

  # price returns:
  # {"bitcoin"=>{"usd"=>47470}}
  def coin_value(amt,coin,currency='usd')
    name = coin_by_symbol(coin)
    key = "#{name}_#{currency}"
    res = @cache.get "coingecko_price_#{key}" do
      @client.price(name, currency: currency)
    end
    res[name][currency] * amt.to_f
  rescue => e
#    warn(e)
#    warn(e.backtrace[0..5])
    0
  end

  def coin_value_dollars(amt,coin)
    coin_value(amt,coin,'usd').ceil(2)
  end

  # Build a sensible version of the coin_list
  # coin_list returns:
  # {"id"=>"zoomswap", "symbol"=>"zm", "name"=>"ZoomSwap"},
  #
  def coin_by_symbol(coin=nil)
    coin = coin.downcase
    coin_list[coin] ? coin_list[coin]["id"] : coin
  end

  def coin_list
    @coin_cache.get "coingecko_coins" do
      coin_hash = {}
      @client.coins_list.each{|c|
        coin_hash[c["symbol"]] = c
      }
      coin_hash
    end
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