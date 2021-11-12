# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Todo:
#   Handle out array/ errors
#   Output type switching?
#   Rest Client w/timeout not working...
#   Timeout error catch etc
#
# API:
# https://signapool.notallmine.net/api/getTop10Miners
# https://signapool.notallmine.net/api/getMiners
# https://signapool.notallmine.net/api/getCurrentRound
# https://signapool.notallmine.net/api/getConfig
# https://signapool.notallmine.net/api/getWonBlocks
#
require 'rest-client'
require 'json'

class SignumPoolView < Base
  using DynamicHash

  attr_accessor :signum_network, :pool_records

  def initialize(p={})
    super
    @title = @config["title"] || 'Signa Pool View'
    @pool_records = @config["record_count"] || 10
    @show_block_winners = @config["show_block_winners"] || true
    @highlight_nodes = @config["highlight_nodes"] || []
  end

  def show_block_winners?
    @show_block_winners == 1 || @show_block_winners == true || @show_block_winners == 'true'
  end
  
  def check(url,addr)
    res = simple_rest([url,'api','getMiners'].join('/'))
    res2 = simple_rest([url,'api','getCurrentRound'].join('/'))
    res3 = simple_rest([url,'api','getConfig'].join('/'))
    res4 = simple_rest([url,'api','getWonBlocks'].join('/'))
    format(res,res2,res3,res4,addr)
  end
  
  def format(res,res2,res3,res4,addr)
    h = structure
    h["config"] = res3
    h["round"] = res2
    h["poolCapacity"] = res["poolCapacity"]
    h["poolSharedCapacity"] = res["poolSharedCapacity"]
    h["poolTotalEffectiveCapacity"] = res["poolTotalEffectiveCapacity"]
    h["miners"] = []
    h["blocks"] = res4["wonBlocks"][0..50]
    h["name"] = addr

    pos = 1
    res["miners"].each{|m|
      mh = {}
      mh["address"] = m["address"]
      mh["address_rs"] = m["addressRS"]      
      mh["pending_balance"] = m["pendingBalance"].split(' ')[0].to_f    
      mh["physical_capacity"] = m["totalCapacity"].to_f                
      mh["effective_capacity"] = m["totalEffectiveCapacity"].to_f         
      mh["shared_capacity"] = m["sharedCapacity"].to_f                 
      mh["tib_commitment"] = m["commitment"].split(' ')[0].to_f        
      mh["total_commitment"] = m["committedBalance"].split(' ')[0].to_f  
      mh["share_percent"] = m["sharePercent"]                         
      mh["confirmations"] = m["nConf"]                                
      mh["pool_share"] = (m["share"] * 100.0).ceil(3)              
      mh["payout"] = m["minimumPayout"].split(' ')[0]
      mh["boost_pool"] = m["boostPool"]
      mh["current_best_deadline"] = m["currentRoundBestDeadline"]      
      mh["name"] = m["name"] || m["addressRS"]        
      mh["agent"] = m["userAgent"]
      mh["pool_position"] = pos
      pos=pos+1
      h["miners"] << mh
    }
    h    
  end

  def structure
    {}
  end

  # TODO: rework to be generic table to be rendered in console or html
  def console_out(data)
    hash = data[:addresses]
    $pastel = Pastel.new
    out = []

    hash.keys.sort.each{|addr|
      
      label_format = "%-25s: %12s │ %6s │ %4s │ %3s │ %8s │ %5s │ %5s │ %7s │ %7s │ %7s "
      column_format = "%-25s: %12s │ %6s │ %4s │ %15s │ %8.2f │ %5s │ %5s │ %7s │ %7s │ %7s "
      
      if show_block_winners?
        label_format << "││%-65s"
        column_format << "││%s"
      else
        column_format << "%s"
      end
      
      ah = hash[addr]
      s = sprintf( label_format,
            "Account","Committed","Pool%","Pos#","Cnfx","Pend Pay","Best","PoC+",
            "PhCap","EfCap","ShCap",$pastel.magenta.on_blue.dim.bold(" Last 10 Block Winners")
          )
  
      my_title = " #{title}: #{ah["name"]} #{@config[:extra]} : Top #{pool_records} Records"
      out <<  $pastel.green.on_blue.bold(sprintf("%#{my_title.length}s %#{s.length - (my_title.length + 1) - 16}s",my_title, "Last Checked: #{@last_check} (#{data["last_check_ago"]} seconds ago)"))


      s2 = sprintf(
        "%10s Miners: %s | Capacity: %s TiB | SharedCapacity: %s TiB | EffectiveCapacity: %s TiB",
        " ",ah["miners"].count,ah["poolCapacity"].to_f.round(2), ah["poolSharedCapacity"].to_f.round(2), ah["poolTotalEffectiveCapacity"].to_f.round(2),
      )
      len = s.length - s2.length - 17
      out <<  $pastel.cyan.on_blue.bold(sprintf("%s %#{len}s",s2,""))
      out <<  $pastel.green.on_blue.bold(s)

      
      if ah["down"] == true
        out << sprintf("%15s - %s",addr,ah["message"])
        next
      end
      ah["miners"][0..pool_records-1].each_with_index{|m,i|        
        nconf = m["confirmations"].to_i
        nconf_str = nconf < 115 ? $pastel.yellow.bold(nconf) : $pastel.green.bold(nconf)
        nconf_str = nconf < 100 ? $pastel.red.bold(nconf) : $pastel.green.bold(nconf)
          
        phycap = (m["physical_capacity"]).ceil(2)
        phycap_str = phycap
    
        effcap = (m["effective_capacity"]).ceil(2)
        effcap_str = effcap #phycap > effcap ? $pastel.yellow.bold(effcap) : $pastel.green.bold(effcap)
          
        boost = m["boost_pool"].round(3)
        boost_str = boost <= 1 ? $pastel.yellow.bold(boost) : $pastel.green.bold(boost)
          
        deadline = if m["current_best_deadline"].to_f > 0.01
          (m["current_best_deadline"].to_f / 60).round(2)
        else
          'wait'
        end
                  
        position = "#{m["pool_position"]}"# / #{m["pool_miner_count"]}"
        
        block = if show_block_winners? && (i < 11)
          get_block_winner(ah,i)
        else
          block = ''
        end
        
        name = if m["name"]
          m["name"][0..24]
        else
          m["address_rs"]
        end
        name.gsub!(/ ⛏️⛏️⛏️/,'   ')

        if @highlight_nodes.include?(m["address_rs"])
          #name = $pastel.cyan(name)
        end
          
        out << sprintf( column_format,
          name,m["total_commitment"].ceil(2),
          m["pool_share"].ceil(2),position, nconf_str,
          m["pending_balance"],deadline,
          boost,phycap_str,effcap_str,m["shared_capacity"].ceil(2), block
        )
        
      }
    }
    out

  end
  
  def get_block_winner(data,idx)
    b = data["blocks"][idx]
    reward = if b["reward"] =~ /^Proc/
        "Wait..."
    else
        b["reward"].split(' ')[0] + ' SIG'
    end
    
    $pastel.black.on_blue.bold(sprintf " %9s │ %12s │ %11s",b["height"],b["generatorRS"],reward)    
  end

  def no_esc(s)
    s.gsub /\e\[\d+m/, ""
  end
end