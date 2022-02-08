# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Todo:
#   Document: Allow change from config of Network API
#
class Modules::SignumPoolMiner < Modules::Base
  using IndifferentHash  

  SIGNUM_API_LIST = [
    		"https://europe2.signum.network",
    		"https://europe.signum.network",
    		"https://europe1.signum.network",
    		"https://europe3.signum.network",
    		"https://brazil.signum.network",
    		"https://uk.signum.network",
        "https://signawallet.notallmine.net",
    		"https://canada.signum.network",
    		"https://australia.signum.network",
  ]
  SIGNUM_API_NODE = "https://canada.signum.network"

  def initialize(p={})
    super
    @signum_api_node = @config["api_node"] || SIGNUM_API_NODE
    @title = @config["title"] || 'Signum Pool Miner'
    @coin = "signa"
    @frequency  = @config["every"] || @config["default_frequency"] || 180
    @frequency  = 60 if @frequency < 60
    @headers = [
      "Account","Avail Bal",'Avail $',"Committed",'Commit $',"Blks","Pool%","Position",
      "Cnf","Pend Pay","Best","PoC+","PhCap","EfCap","ShCap"
    ]

  end
  
  def check(url,addr)
    res = simple_rest([url,'api','getMiner',addr].join('/'))
    res2 = simple_rest("#{@signum_api_node}/burst?requestType=getAccount&account=#{addr}")
    res3 = simple_rest("#{@signum_api_node}/burst?requestType=getAccountBlockIds&account=#{addr}")  
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
    h = node_structure
    h.name              = res["name"] || res["addressRS"]        
    h.address           = res["address"]
    h.address_rs        = res["addressRS"]      
    h.balance           = res2["balanceNQT"].to_i / 100000000.0
    h.available_balance = res2["unconfirmedBalanceNQT"].to_i / 100000000.0
    h.pending_balance   = res["pendingBalance"].split(' ')[0].to_f    
    h.physical_capacity = res["totalCapacity"].to_f                   
    h.effective_capacity = res["totalEffectiveCapacity"].to_f         
    h.shared_capacity   = res["sharedCapacity"].to_f                 
    h.tib_commitment    = res["commitment"].split(' ')[0].to_f        
    h.total_commitment  = res["committedBalance"].split(' ')[0].to_f  
    h.share_percent     = res["sharePercent"]                         
    h.donation_percent  = res["donationPercent"]                      
    h.confirmations     = res["nConf"]                                
    h.pool_share        = (res["share"] * 100.0).ceil(3)              
    h.payout            = res["minimumPayout"].split(' ')[0]
    h.boost_pool        = boost
    h.current_best_deadline = res["currentRoundBestDeadline"]      
    h.agent             = res["userAgent"]
    h.blocks            = res3["blockIds"].count
    h.pool_position     = pos
    h.pool_miner_count  = res4["miners"].count
    h
  end

  def node_structure
    OpenStruct.new({
      "name"              => "",             
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
      "agent"             => "",
      "blocks"            => 0,
      "pool_position"     => 0,
      "pool_miner_count"  => 0
    })   
  end

  def tableize(data)
    tables = []
    tables << super(data) do |item,rows,formats|
      addr = item.address
      nconf = item.confirmations.to_i || 0
      nconf_str = colorize_simple_threshold(nconf,"<",115,110)
      
      phycap = (item.physical_capacity).to_f.ceil(2)
      phycap_str = config["capacity"] && config["capacity"][addr] && (phycap < config["capacity"][addr]) ? pastel.yellow.bold(phycap) : pastel.green.bold(phycap)

      effcap = (item.effective_capacity).to_f.ceil(2)
      effcap_str = phycap > effcap ? pastel.yellow.bold(effcap) : pastel.green.bold(effcap)
      
      boost = item.boost_pool.to_f.round(3)
      boost_str = boost <= 1 ? pastel.yellow.bold(boost) : pastel.green.bold(boost)
      
      deadline = if item.current_best_deadline.to_f > 0.01
        (item.current_best_deadline.to_f / 60).round(2)
      else
        'wait'
      end
      
      position = "#{item.pool_position} / #{item.pool_miner_count}"
      rows << [
        item.name,
        item.available_balance.ceil(4), coin_value_dollars(item.available_balance,@coin),
        item.total_commitment.ceil(4), coin_value_dollars(item.total_commitment,@coin),
        item.blocks, item.pool_share.ceil(4),position,nconf_str,
        item.pending_balance, deadline,
        boost_str, phycap_str, effcap_str, item.shared_capacity.to_f.ceil(2)
      ]
    end
    tables
  end
     
end