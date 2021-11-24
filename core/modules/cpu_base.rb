# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class CpuBase < Base
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
    colorize(s2,color_str)
  end

end