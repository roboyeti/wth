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
    @coin_hash = {}

    @lifespan = p[:lifespan] || 180
    @coin_cache = Lightly.new(dir: 'tmp/coingecko_cache', life: 86400 , hash: false)
    @cache = Lightly.new(dir: 'tmp/coingecko_cache', life: @lifespan , hash: false)
#    coin_list # Init cached data storage
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
    # Coingecko created a bug in their data, eith 'eth' now returning ethereum-wormhole, listed under 'eth' symbol...grrr.
    # I let them know, but here is a work around.
    if coin == 'eth'
      'ethereum'
    else
      coin_list[coin] ? coin_list[coin]["id"] : coin
    end
  end

  def coin_list
    return @coin_hash if !@coin_hash.empty?
    @coin_cache.get "coingecko_coins" do
      @client.coins_list.each{|c|
        @coin_hash[c["symbol"]] = c
      }
      @coin_hash
    end
  end

end