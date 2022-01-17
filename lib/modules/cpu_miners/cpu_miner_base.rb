# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class Modules::CpuMinerBase < Modules::Base
  using IndifferentHash  

  attr_reader :standalone

  def initialize(p={})
    super
    @standalone = @config["standalone"]
  end

  def mine_profit(*p)
    self.respond_to?(:mine_profit_hook) ? mine_profit_hook(*p) : 0
  end

  def mine_revenue(*p)
    self.respond_to?(:mine_revenue_hook) ? mine_revenue_hook(*p) : 0
  end

  def calc_estimated_revenue(item)
    sprintf("$%0.2f",mine_revenue(item.coin,item.combined_speed).to_f)
  end

  # TODO: Add cpu gathering to a remote service version
  def cpu_model(*p)
    self.respond_to?(:cpu_model_hook) ? cpu_model_hook(*p) : ''
  end

  # Colors s2
  def colorize_percent_of(s1,s2,pwarn,palert)
    color_str = if s2 > (s1 * palert)
      $color_miner_alert     
    elsif s2 > (s1 * pwarn)
	  $color_miner_warn
    else
	  $color_miner_ok
    end
    colorit(s2,color_str)
  end

  def cm_node_structure(host,addr)
    node = node_structure()
    ip,port,coin = addr.split(':')
    node.name = host
    node.ip = ip
    node.port = port.blank? ? self.port : port
    node.coin = coin.blank? ? self.coin : coin
    node.address = "#{node.ip}:#{node.port}"
    node.cpu = cpu_structure
    node.estimated_revenue = 0.0
    node.miner = ""
    node.version = ""
    node
  end
end