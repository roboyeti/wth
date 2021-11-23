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
# The request we use, which allows us to do our own math, so we can cache the request and make it still useful
#   https://whattomine.com/coins/151.json?hr=1.0&p=0.0&fee=0.0&cost=0.0&hcost=0.0&span_br=1h&span_d=24
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
		calc: 	"coins/@coin_id.json?hr=1&p=@power&fee=0.0&cost=@cost&hcost=0.0&span_br=1h&span_d=24"
	}
	
	def initialize(p={})
		super
		@sema_calc = Concurrent::Semaphore.new(1)
		@sema_coin = Concurrent::Semaphore.new(1)
		@lifespan = p[:lifespan] || 300
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

	def profit(coin,speed,power=0,cost=0.1)
		return reward_structure if !coin || coin.empty?
		coin_id = coin_id(coin)
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
		ret.coin_rewards = speed * resp["estimated_rewards"].to_f
		ret.btc_revenue = speed * resp["btc_revenue"].to_f
		ret.dollar_revenue = speed * (resp["revenue"].gsub(/\$|\,/,'')).to_f.round(4)
		ret
	end

	def profit_dollars(coin,speed,power=0,cost=0.1)
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
end