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
require 'rest-client'
require 'json'

class SignumPoolMiner < Base
  using DynamicHash

  SIGNUM_NETWORK_API = 'https://canada.signum.network'

  def initialize(p={})
    super
    @title = p[:title] || 'Signa Pool Miner'    
  end

  def check_all
    tchk = (Time.now - @last_check)
    if @data.empty? || tchk > @config[:every]
      out = []
      @data = { addresses: {} }    
      addresses = @config[:nodes].keys.sort
      
      addresses.each {|k|
        v = @config[:nodes][k]
        @data[:addresses][k] = {}
        begin
          if @down[k]
            if (Time.now - @down[k]) < 180
                  @data[:addresses][k] = {
                    "down" => true,
                    "message" => "Service down!  Checked @ #{@down[k]} #{(Time.now - @down[k]).round(2)} seconds ago",
                    "time"  => Time.now,
                  }
            else
              out << line_err(k,"Rechecking service.")
              @down.delete(k)
            end
          else
            h = check(v,k)
            @data[:addresses][k] = h
          end
        rescue => e
          @down[k] = Time.now
          @data[:addresses][k] = {
            "down" => true,
            "error" => e,
            "backtrace" => e.backtrace[0..4],
            "time"  => Time.now,
            "message" => "Service down!  Checked @ #{@down[k]} #{(Time.now - @down[k]).round(2)} seconds ago",
          }
        end
      }
      @last_check = Time.now
    end

    @data[:last_check_ago] = (Time.now - @last_check).to_i
    @data
  end
  
  def check(url,addr)
    res = simple_rest([url,'api','getMiner',addr].join('/'))
    res2 = simple_rest("#{SIGNUM_NETWORK_API}/burst?requestType=getAccount&account=#{addr}")
    res3 = simple_rest("#{SIGNUM_NETWORK_API}/burst?requestType=getAccountBlockIds&account=#{addr}")
    res4 = simple_rest([url,'api','getMiners'].join('/'))
    format(res,res2,res3,res4,addr)
  end

  # Todo: break into parts...
  def format(res,res2,res3,res4,addr)
    boost = res["boostPool"][res["nConf"].to_i - 1] # Get PoC+
    pos = 0
    me = res4["miners"].find{|a|
      pos = pos + 1
      a["address"] == res["address"]
    } 
    h = structure
    h["address"] = res["address"]
    h["address_rs"] = res["addressRS"]      
    h["balance"] = res2["balanceNQT"].to_i / 100000000.0
    h["available_balance"] = res2["unconfirmedBalanceNQT"].to_i / 100000000.0
    h["pending_balance"] = res["pendingBalance"].split(' ')[0].to_f    
    h["physical_capacity"] = res["totalCapacity"].to_f                   
    h["effective_capacity"] = res["totalEffectiveCapacity"].to_f         
    h["shared_capacity"] = res["sharedCapacity"].to_f                 
    h["tib_commitment"] = res["commitment"].split(' ')[0].to_f        
    h["total_commitment"] = res["committedBalance"].split(' ')[0].to_f  
    h["share_percent"] = res["sharePercent"]                         
    h["donation_percent"] = res["donationPercent"]                      
    h["confirmations"] = res["nConf"]                                
    h["pool_share"] = (res["share"] * 100.0).ceil(3)              
    h["payout"] = res["minimumPayout"].split(' ')[0]
    h["boost_pool"] = boost
    h["current_best_deadline"] = res["currentRoundBestDeadline"]      
    h["name"] = res["name"] || res["addressRS"]        
    h["agent"] = res["userAgent"]
    h["blocks"] = res3["blockIds"].count
    h["pool_position"] = pos
    h["pool_miner_count"] = res4["miners"].count
    h
  end

  def structure
    {
      "address"           => "",
      "address_rs"        => "",      
      "balance"           => 0.0,
      "available_balance" => 0.0,
      "pending_balance"   => 0.0,    
      "physical_capacity" => 0.0,                   
      "effective_capacity" => 0.0,         
      "shared_capacity"    => 0.0,                 
      "tib_commitment"    => 0.0,        
      "total_commitment"  => 0.0,  
      "share_percent"     => 0.0,                         
      "donation_percent"  => 0.0,                      
      "confirmations"     => 0,                                
      "pool_share"        => 0.0,              
      "payout"            => 0.0,
      "boost_pool"        => 0.0,
      "current_best_deadline" => 0.0,         
      "name"              => "",             
      "agent"             => "",
      "blocks"            => 0,
      "pool_position"     => 0,
      "pool_miner_count"  => 0
    }     
  end
  
  def console_out(data)
    hash = data[:addresses]
    $pastel = Pastel.new
    out = []

    headers = [
      "Account","Avail Bal","Committed","Blks","Pool%","Position",
      "Cnf","Pend Pay","Best","PoC+","PhCap","EfCap","ShCap"
    ]

    title = sprintf "#{nice_title} %30s","Last Checked: #{data[:last_check_ago].ceil(2)} seconds ago"

    rows = []
    hash.keys.sort.map{|addr|
      h = hash[addr]

      if h["down"] == true
        h["name"] = addr
        h[:uptime] = colorize("down",$color_alert)
        @events << $pastel.red(sprintf("%s : %22s: %s",Time.now,addr,h["message"]))
      end
      
      nconf = h["confirmations"].to_i
      nconf_str = nconf < 100 ? $pastel.red.bold(nconf) : $pastel.green.bold(nconf)
      nconf_str = nconf < 115 ? $pastel.yellow.bold(nconf) : $pastel.green.bold(nconf)
      
      phycap = (h["physical_capacity"]).to_f.ceil(2)
      phycap_str = ""
      phycap_str = @config["capacity"] && @config["capacity"][addr] && (phycap < @config["capacity"][addr]) ? $pastel.yellow.bold(phycap) : $pastel.green.bold(phycap)

      effcap = (h["effective_capacity"]).to_f.ceil(2)
      effcap_str = phycap > effcap ? $pastel.yellow.bold(effcap) : $pastel.green.bold(effcap)
      
      boost = h["boost_pool"].to_f.round(3)
      boost_str = boost <= 1 ? $pastel.yellow.bold(boost) : $pastel.green.bold(boost)
      
      deadline = if h["current_best_deadline"].to_f > 0.01
        (h["current_best_deadline"].to_f / 60).round(2)
      else
        'wait'
      end
      
      position = "#{h["pool_position"]} / #{h["pool_miner_count"]}"
      rows << [
        h["name"],h["available_balance"].ceil(4),h["total_commitment"].to_f.ceil(4),
        h["blocks"],h["pool_share"].to_f.ceil(4),position,nconf_str,
        h["pending_balance"],deadline,
        boost_str,phycap_str,effcap_str,h["shared_capacity"].to_f.ceil(2)
      ]
      
    }
    table_out(headers,rows,title)
  end
   
end