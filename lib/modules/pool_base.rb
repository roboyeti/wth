# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'

class PoolBase < Base

  def initialize(p={})
  	super
    @worker_row    = @config["worker_row"] || 5
  end
  
  def pool_structure
    OpenStruct.new({
      "name": '',
      "address": '',
      "private_address": '',
      "available_balance": 0.0,
      "pending_balance": 0.0,
      "unpaid_balance": 0.0,
      "uuid": '',
      "workers_up": 0,
      "workers_down": 0,      
      "algo": '',
      "mining_fee": '',
      "auto_pay": false,
      "enabled": '',
      "network": '',
      "coin": '',
      "speed": 0.0,
      "calc_speed": 0.0,
      "avg_speed": 0.0,
      "accepted": 0.0,
      "rejected": 0.0,
      "stale": 0.0,
      "workers": [],
      "status": 'ok',
      "timestamp": Time.now
    })
  end
  def structure
    pool_structure  
  end
  
  def worker_structure
    OpenStruct.new({
      "online": false,
      "name": "???",
      "algo": '???',
      "uptime": 0,
      "last_seen": 0,
      "speed": 0.0,
      "calc_speed": 0.0,
      "avg_speed": 0.0,
      "accepted": 0.0,
      "rejected": 0.0,
      "stale": 0.0,
    })
  end
  
  def colorize_workers(h)
    colorize_up_down_compare(h.workers_up,h.workers_down)
  end

  def colorize_up_down_compare(up,down)
    up ||= 0
    down ||= 0
    my_str = "#{up}/#{down}"
    if up == 0
      colorize(my_str,$color_pool_updown_alert)
    elsif down > 0
      colorize(my_str,$color_pool_updown_warn)      
    else
      colorize(my_str,$color_pool_updown_ok)      
    end
  end

  # Colors s2
  def colorize_percent_of(s1,s2,pwarn,palert)
    s1 ||= 0
    s2 ||= 0
    if s2 > (s1 * palert)
      colorize(s2,$color_pool_alert)      
    elsif s2 > (s1 * pwarn)
      colorize(s2,$color_pool_warn)      
    else
      colorize(s2,$color_pool_ok)      
    end  
  end
  
  # Colors s2
  def colorize_speed_compare(s1,s2)
    s1 ||= 0
    s2 ||= 0
    if s2 < (s1 * $pool_speed_compare_percent_alert)
      colorize(s2,$color_pool_speed_compare_alert)      
    elsif s2 < (s1 * $pool_speed_compare_percent_warn)
      colorize(s2,$color_pool_speed_compare_warn)      
    else
      colorize(s2,$color_pool_speed_compare_ok)      
    end  
  end

end
