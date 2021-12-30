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
class Modules::SignumPoolView < Modules::Base
  using IndifferentHash  

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
    h = OpenStruct.new({})
# TODO: Keep?
    h.config = res3
    h.round = res2
#
    h.poolCapacity = res["poolCapacity"]
    h.poolSharedCapacity = res["poolSharedCapacity"]
    h.poolTotalEffectiveCapacity = res["poolTotalEffectiveCapacity"]
    h.miners = []
    h.blocks = res4["wonBlocks"][0..@config["record_count"]]
    h.name = addr

    pos = 1
    res["miners"].each{|m|
      mh = miner_structure
      mh.address = m["address"]
      mh.address_rs = m["addressRS"]      
      mh.pending_balance = m["pendingBalance"].split(' ')[0].to_f    
      mh.physical_capacity = m["totalCapacity"].to_f                
      mh.effective_capacity = m["totalEffectiveCapacity"].to_f         
      mh.shared_capacity = m["sharedCapacity"].to_f                 
      mh.tib_commitment = m["commitment"].split(' ')[0].to_f        
      mh.total_commitment = m["committedBalance"].split(' ')[0].to_f  
      mh.share_percent = m["sharePercent"]                         
      mh.confirmations = m["nConf"]                                
      mh.pool_share = (m["share"] * 100.0).ceil(3)              
      mh.payout = m["minimumPayout"].split(' ')[0]
      mh.boost_pool = m["boostPool"]
      mh.current_best_deadline = m["currentRoundBestDeadline"]      
      mh.name = m["name"] || m["addressRS"]        
      mh.agent = m["userAgent"]
      mh.pool_position = pos
      pos=pos+1
      h.miners << mh
    }
    h    
  end

  def node_structure
    OpenStruct.new({
      "name" => '',
      "address" => '',
      "uptime" => 0,
      "config" => {},
      "round" => {},
      "poolCapacity" => 0.0,
      "poolSharedCapacity" => 0.0,
      "poolTotalEffectiveCapacity" => 0.0,
      "miners" => [],
      "blocks" => [],
    })
  end
  
  def miner_structure
    OpenStruct.new({
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
    })   
  end

  # Todo: Fix DOWN...
  def console_out(data)
    hash = data[:addresses]
    my_title = ''
    my_stats = ''
    block_headers = ["Height","Address","Reward"]
    headers = [
      "Account","Committed","Pool%","Pos#","Conf","Pend Pay","Best","PoC+",
      "PhCap","EfCap","ShCap"
    ]
    rows = []
    block_rows = []
        
    hash.keys.sort.each{|addr|
      h = hash[addr]

      # Fix DOWN...
      if h["down"] == true
        #out << sprintf("%15s - %s",addr,h["message"])
        #next
      end
  
      my_title = " #{title}: #{h["name"]} #{@config[:extra]} : Top #{pool_records} Records : Last Checked: #{@last_check} (#{data["last_check_ago"]} seconds ago)"

      my_stats = sprintf(
        "%10s Miners: %s | Capacity: %s TiB | SharedCapacity: %s TiB | EffectiveCapacity: %s TiB",
        " ",h.miners.count, h.poolCapacity.to_f.round(2), h.poolSharedCapacity.to_f.round(2), h.poolTotalEffectiveCapacity.to_f.round(2),
      )

      h.miners[0..pool_records-1].each_with_index{|m,i|        
        nconf = m.confirmations.to_i || 0
        nconf_str = colorize_simple_threshold(nconf,"<",115,110)
                    
        boost = m.boost_pool.round(3)
        boost_str = boost <= 1 ? $pastel.yellow.bold(boost) : $pastel.green.bold(boost)
          
        deadline = if m.current_best_deadline.to_f > 0.01
          (m.current_best_deadline.to_f / 60).round(2)
        else
          'wait'
        end
        
        name = safe_miner_address(m)
        
        if @highlight_nodes.include?(m.address_rs)
          name = $pastel.green(name)
        end
          
        rows << [
          name, m.total_commitment.ceil(2), m.pool_share.ceil(2), m.pool_position, nconf_str, m.pending_balance,
          deadline, boost, m.physical_capacity.ceil(2), m.effective_capacity.ceil(2), m.shared_capacity.ceil(2)
        ]
      }
    }

    hash.keys.sort.each{|addr|
      h = hash[addr]
 
      if show_block_winners?
        h.blocks[0..pool_records-1].each_with_index{|b,i|
           block_rows << get_block_winner(h,i)
        }
      end
    }
 
    b = !block_rows.empty? ? table_out(block_headers, block_rows, "Last #{pool_records} Block Winners") : ''
    
    t = table_out(headers,rows,my_stats)
    table_out([" "," "],[[t,b]],my_title)

  end
  
  # Try to bring miner text addresses into line
  # TODO: Make something like this that user can append to
  # and apply for other modeuls (move to base or module)
  #
  # @return [String] A nicer name ...
  #
  def safe_miner_address(m)
    name = if m["name"]
      m["name"][0..24]
    else
      m["address_rs"]
    end
    name.gsub!(/ ⛏️⛏️⛏️/,'   ')

    # No Escape ... brutal, but may be necessary
    # s.gsub /\e\[\d+m/, ""
    name
  end
  
  # Get the block winner data at any index
  # TODO: This isn't really needed anymore, as it was created when a block line
  #       had to be appended to a miner line pre-table design
  #
  # @params [Hash|OpenStrust] data The specific address structure being processed
  # @params [Integer] idx The index of the block to process
  # @return [Array] Array of that index entry height, miner address, and reward fr block
  #
  def get_block_winner(data,idx)
    b = data["blocks"][idx] || {}
    reward = if b["reward"] =~ /^Proc/
        "Wait..."
    else
        b["reward"].split(' ')[0] + ' SIG'
    end

    addr = b["generatorRS"]    
    if @highlight_nodes.include?(addr)
      addr = $pastel.green(addr)
    end

    [ b["height"],addr,reward ]
  end

end