# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# https://api.unminable.com/v4/address/0xBC31664a2200643Bc0C7884E8c59531B1e0B2c1d?coin=etc
# https://api.unminable.com/v4/account/88577ee8-2d8d-433b-ae44-2a4da69c155d/workers
require 'rest-client'
require 'json'

class Unmineable < Base
  using DynamicHash
  
  API_HOST = "https://api.unminable.com/v4"

  def initialize(p={})
    super
    @title = p[:title] || 'Unmineable'
  end

  def check(info,type)
    (addr,uuid,coin) = info.split(":")
    res1 = simple_rest([API_HOST,'address',"#{addr}?coin=#{coin}"].join('/'))
    res2 = simple_rest([API_HOST,'account', uuid, 'workers'].join('/'))
    format(type,res1,res2)
  end
  
  def format(name,res1,res2)
    h = structure
    data = res1["data"]
    h["name"] = name
    h["address"] = data["address"]
    h["available_balance"] = data["balance_payable"]
    h["uuid"] = data["uuid"]
    h["mining_fee"] = data["mining_fee"]
    h["auto_pay"] = data["auto"]
    h["coin"] = data["network"]
    h
  end

  def structure
    {}
  end

  # TODO: rework to be generic table to be rendered in console or html
  def console_out(data)
    hash = data[:addresses]
    out = []
    hash.keys.sort.map{|addr|
      h = hash[addr]

      if h["down"] == true
        out << sprintf("%15s - %s",addr,h["message"])
        next
      end

      out << sprintf(" %20s %10s : %12s %s , Mining Fee=%4s , Auto Pay=%4s",
        $pastel.yellow.on_magenta.bold("  #{title}  "),h["name"],h["available_balance"],h["coin"],h["mining_fee"],h["auto_pay"]
      )
    }
    out      
  end
end