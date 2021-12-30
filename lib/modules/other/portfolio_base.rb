# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class Modules::PortfolioBase < Modules::Base
  using IndifferentHash

  def initialize(p={})
    super
  end

  def structure
    OpenStruct.new({
      id:		"",
      symbol:	"",
      name:		"",
      time:		Time.now,
      currency: "",
      price:	0.0,
      holding: 0.0,
      cost: 0.0,
      market_cap:		0,
      market_rank:		0,
      total_volume:		0,
      high_24h:			0,
      low_24h:			0,
      price_change_24h:	0.0,
      price_change_percent_24h:	0.0,
      circulating_supply:		0.0,
      total_supply:		0.0,
      last_updated:		"",
      cached_time: 		"",
      round: 8,
    })
  end
  
end