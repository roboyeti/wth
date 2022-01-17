# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Base class for GPU APIs.
#
class Modules::GpuMinerBase < Modules::Base
  using IndifferentHash  
  
  attr_reader :header_length, :gpu_row, :standalone
 
  def initialize(p={})
    super

    # Config variables
    @standalone = @config["standalone"]
    @gpu_row    = @config["gpu_row"] || 5
    if @standalone == true
      @gpu_row = 1
    end

    # Internal variables
    @devices = {}
    @headers = ['Node','Uptime','Ver','ERev$','Speed','Power','Shares','Rjct','Pool','GPU#']

    register_config_option("standalone",false,[],"Optional display mode to show data using more vertical space for single screen per/node use for a head display.")
    register_config_option("gpu_row",5,[],"Optional value to set number of GPUs displayed per row.  Default is 5.")
  end

  # Checks for a registered profit hook and calls it, returning calculated
  # value from the used plugin or 0 if no plugin
  #
  def mine_profit(*p)
    self.respond_to?(:mine_profit_hook) ? mine_profit_hook(*p) : 0
  end

  # Checks for a registered revenue hook and calls it, returning calculated
  # value from the used plugin or 0 if no plugin
  #
  def mine_revenue(*p)
    self.respond_to?(:mine_revenue_hook) ? mine_revenue_hook(*p) : 0
  end

  def calc_estimated_revenue(item)
    sprintf("$%0.2f",mine_revenue(item.coin,item.combined_speed).to_f)
  end

  def tableize(data)
    tables = []
    @max_gpu = 0
    gpu_cnt = 0

    table = super(data) do |item,rows,formats,headers|
      standalone? ? tableize_standalone(item,rows,formats,headers) : tableize_normal(item,rows,formats,headers)
    end
    table.headers = [' '] if standalone?
    @max_gpu.times {|i|
      table.headers.concat [' Id','Spd','Tmp','Fan']
    }
    tables << table
  end

  def tableize_normal(item,rows,formats,headers)
      reject_str = colorize_percent_of(item.total_shares,item.rejected_shares,0.10,0.50)

      row = [
        item.name.capitalize, item.uptime, item.version,
        sprintf("$%0.2f",mine_revenue(coin,item.combined_speed).to_f), # h[:coin] ||  .... erg
        item.combined_speed.round(0),
        format_power(item.power_total),
        item.total_shares,
        reject_str,
        item.pool,
        item.gpu.keys.count
      ]

      gpu_cnt = 0
      item.gpu.each_pair {|id,v|
        gpu_cnt += 1
        # We have reached default or user defined max of gpu per row
        # Finish row and start a new one with padding
        if gpu_cnt > gpu_row
          gpu_cnt = 0
          rows << row
          row = headers.count.times.map{ ' ' }
        end
        $id_format = "%-s"
        row.concat([
          sprintf(" #{$id_format}",id),
          sprintf("#{$id_format}",speed_style(v[:gpu_speed].to_f.round(1))),
          sprintf("#{$id_format}",temp_style(v[:gpu_temp].to_i)),
          sprintf("#{$id_format}",fan_style(v[:gpu_fan].to_i))
        ])
        if gpu_cnt > @max_gpu
          @max_gpu = gpu_cnt
        end
      }
      rows << row
  end

  def tableize_standalone(item,rows,formats,headers)
      reject_str = colorize_percent_of(item.total_shares,item.rejected_shares,0.10,0.50)

      i_row = [
        item.uptime,
        ite.version,
        sprintf("$%0.2f",mine_revenue(coin,item.combined_speed).to_f), # h[:coin] ||  .... erg
        item.combined_speed.round(0),
        format_power(item.power_total),
        item.total_shares,
        reject_str,
      ]
      item_hdrs = headers.dup
      item_hdrs.delete_at(0)
      item_hdrs.delete_at(-1)
      item_hdrs.delete_at(-1)
      rows << [' ']
      rows << [ table_out(item_hdrs,[i_row,[]],"#{item.name.capitalize} : #{item.pool}") ]

      gpu_hdrs = [' BusId','  Speed','  Temp','  Fan']
      gpu_rows = []
      item.gpu.each_pair {|id,v|
        $id_format = "%-s"
        gpu_rows << [
          sprintf(" #{$id_format}",id),
          sprintf("#{$id_format}",speed_style(v[:gpu_speed].to_f.round(1))),
          sprintf("#{$id_format}",temp_style(v[:gpu_temp].to_i)),
          sprintf("#{$id_format}",fan_style(v[:gpu_fan].to_i))
        ]
      }
      rows << [' ']
      rows << [ table_out(gpu_hdrs,gpu_rows,"GPU Devices").split("\n").map{|t| "\t\t#{t}\n"} ]
  end

  # Colors s2
  def colorize_percent_of(s1,s2,pwarn,palert)
    my_str = if s2 > (s1 * palert)
      colorize(s2,$color_gpu_alert)      
    elsif s2 > (s1 * pwarn)
      colorize(s2,$color_gpu_warn)      
    else
      colorize(s2,$color_gpu_ok)      
    end  
  end

  def cm_node_structure(host,addr)
    node = node_structure()
    ip,port,coin = addr.split(':')
    node.name = host
    node.ip = ip
    node.port = port.blank? ? self.port : port
    node.coin = coin.blank? ? self.coin : coin
    node.address = "#{node.ip}:#{node.port}"
    node.estimated_revenue = 0.0
    node.pool = ""
    node.miner = ""
    node.version = ""
    node
  end
end
