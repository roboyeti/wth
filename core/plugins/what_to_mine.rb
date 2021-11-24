# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Coin request:
#   https://whattomine.com/calculators.json 
# ETH request:
# Revenue request with speed and power
#   https://whattomine.com/coins/151.json?hr=151.0&br_enabled=true&br=2.17&d_enabled=true&d=1.09840192378888e%2B16&p=400.0&fee=0.0&er_enabled=true&er=0.07079600&cost=0.1&hcost=0.0&btc_enabled=true&btc=64100.99&span_br=1h&span_d=24
#
# https://whattomine.com/coins.json?eth=true&factor[eth_hr]=155.0&factor[cost]=0.0&sort=Profitability24&volume=0&revenue=24h&factor[exchanges][]=&factor[exchanges][]=binance&factor[exchanges][]=bitfinex&factor[exchanges][]=bitforex&factor[exchanges][]=bittrex&factor[exchanges][]=coinex&factor[exchanges][]=dove&factor[exchanges][]=exmo&factor[exchanges][]=gate&factor[exchanges][]=graviex&factor[exchanges][]=hitbtc&factor[exchanges][]=hotbit&factor[exchanges][]=ogre&factor[exchanges][]=poloniex&factor[exchanges][]=stex&dataset=Main
# https://whattomine.com/coins.json?eth=true&factor[eth_hr]=155.0&factor[cost]=0.0&sort=Profitability24&volume=0&revenue=24h&dataset=Main
#
# The request we use, which allows us to do our own math, so we can cache the request and make it still useful
# URL: https://whattomine.com/coins/151.json?hr=100.0&p=0.0&fee=0.0&cost=0.0&hcost=0.0&span_br=24&span_d=24
# Note: We request 100 speed units / divide by 100 and multiply by speed 
#
# TODO: enable power cost
#
require 'lightly'
require 'concurrent'
class WhatToMine < PluginBase
  using IndifferentHash  
  
	attr :lifespan
	attr_reader :cache
	
	URL = "https://whattomine.com"
	CMD = {
		coins: 	"calculators.json",
		calc: 	"coins/@coin_id.json?hr=100&p=@power&fee=0.0&cost=@cost&hcost=0.0&span_br=24&span_d=24",
		'NICEHASH_ETH': "coins.json?eth=true&factor[eth_hr]=100.0&factor[cost]=0.0&sort=Profitability24&volume=0&revenue=24h&dataset=Main"
	}

  FIXUPS = {
    'NICEHASH_ETH': ['ETH','nicehash_eth_fix'],
  }

	def initialize(p={})
		super
		@sema_calc = Concurrent::Semaphore.new(1)
		@sema_coin = Concurrent::Semaphore.new(1)
		@lifespan = p[:lifespan] || 180
		@cache = Lightly.new dir: 'tmp/wtm_cache', life: 300, hash: false
		coins # Init cached data storage
	end
	
	def register
		@registry ||= Sash.new(
			'mine_profit' => 'profit_dollars',
			'mine_revenue' => 'revenue_dollars'
		)
	end
	
	def flush
		@cache.flush
	end

	def revenue(coin,speed)
		profit(coin,speed,0,0)
	end

	def revenue_dollars(coin,speed)
		h = revenue(coin,speed)
		h.dollar_revenue.round(2)
	end

	def profit(coin,speed,power=0,cost=0.0)
		return reward_structure if !coin || coin.empty?
		chk_coin = FIXUPS[coin] ? FIXUPS[coin][0] : coin

		coin_id = coin_id(chk_coin)
		return reward_structure if !coin_id

		@sema_calc.acquire
		resp = @cache.get "coin_calc_#{coin_id}" do
			req = CMD[:calc].dup
			['coin_id','speed','power','cost'].each{|var|
				req.gsub!(/\@#{var}/,eval("#{var}").to_s)
			}
			url = [URL,req].join('/')
			resp = simple_rest(url)
		end
		@sema_calc.release
		ret = reward_structure
		ret.coin_rewards = speed * (resp["estimated_rewards"].to_f / 100)
		ret.btc_revenue = speed * (resp["btc_revenue"].to_f / 100)
		ret.dollar_revenue = speed * ((resp["revenue"].gsub(/\$|\,/,'')).to_f / 100).round(4)

    if FIXUPS[coin]
      self.send(FIXUPS[coin][1],ret)
    end

		ret
	end

	def profit_dollars(coin,speed,power=0,cost=0.0)
		h = profit(coin,speed,power,cost)
		h.dollar_revenue.round(2)
	end

	def reward_structure
		OpenStruct.new({
				"coin_rewards": 0.0,
				"btc_revenue": 0.0,
				"dollar_revenue": 0.0,
				#"cost": 0.0,
				#"profit": 0.0
		})
	end
	
	def calculators
		@cache.get 'calculators' do
			url = [URL,CMD[:coins]].join('/')
			simple_rest(url)
		end
	end
	
	def coins
		@sema_coin.acquire
		resp = @cache.get 'coins' do
			ret = OpenStruct.new({})
			#h = calculators
			calculators["coins"].each_pair{|k,v|
				ret[v["tag"]] = OpenStruct.new({ "id" => v["id"], "algo" => v["algorithm"], "name" => k })
			}
			ret
		end
		@sema_coin.release
		resp
	end

	def coin_id(coin)
		coins[coin] ? coins[coin]["id"]	: nil
	end

#================================================================================
# FIXUPS
#   Fixups are for unusual cases, such as NiceHash DAGGERHASHIMOTO not having
#   same profit at ETHASH.
#================================================================================
  def nicehash_eth_fix(obj)
    resp = @cache.get 'nicehash_eth' do
			url = [URL,CMD['NICEHASH_ETH']].join('/')
			simple_rest(url)
		end
    obj.dollar_revenue = obj.dollar_revenue * (resp["coins"]["Nicehash-Ethash"]["profitability24"].to_f / 100).round(4)
    obj
  end

end