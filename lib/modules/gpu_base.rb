# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Base class for GPU APIs.
#
class GpuBase < Base
  using IndifferentHash  
  
  attr_reader :header_length, :gpu_row, :standalone
 
  def initialize(p={})
    super
    @devices = @config["devices"] || {}
    @standalone = @config["standalone"]
    @gpu_row    = @config["gpu_row"] || 5
    if @standalone == true
      @gpu_row = 1
    end
  end

  def mine_profit(*p)
    self.respond_to?(:mine_profit_hook) ? mine_profit_hook(*p) : 0
  end

  def mine_revenue(*p)
    self.respond_to?(:mine_revenue_hook) ? mine_revenue_hook(*p) : 0
  end
  
  # General console out creation.
  # See 'templates/gpu_worker.rb' and 'templates/table.rb' for magic global style stuff
  def console_out(data)
    hosts = data['addresses']
    rows = []
    max_gpu = 0 # Track largest number of GPU per row
    
    headers = ['Uptime','Est.Rev','Speed','Power','Shares','Rjct','GPUs >']
    
    hosts.keys.sort.each{|addr|
      h = hosts[addr]
      h = OpenStruct.new(h) if !h.is_a?(OpenStruct)

      if h["down"] == true
        h.name = addr
        h.uptime = colorize("down",$color_alert)
      end

      reject_str = colorize_percent_of(h[:total_shares],h[:rejected_shares],0.10,0.50)

      row = [
        h.uptime,
        sprintf("$%0.2f",mine_revenue(coin,h.combined_speed).to_f), # h[:coin] ||  .... erg
        h.combined_speed.round(0),
        format_power(h.power_total),
        h.total_shares,
        reject_str,
        h.gpu.keys.count
      ]
      if !standalone?
        row.unshift(h.name.capitalize)
      else
        row.unshift('')
      end
      rows << row
    }

#puts rows
    if standalone?
      headers.unshift("")
      k = hosts.keys.sort.first
      o = table_out(headers,rows,"#{hosts[k]["name"].upcase} - #{title} : #{config['extra']}")
      gheaders = []
      grows = []
      gpu_grid(hosts,gheaders,grows)
      o << "\n"
      o << table_out(gheaders,grows)
      o
    else
      headers.unshift("#{title}:#{config['extra']}")
      gpu_grid(hosts,headers,rows)
      table_out(headers,rows)    
    end
  end
    
  def gpu_grid(hash,headers,rows)
    # GPU routine
    row_headers = headers.count
    row_cnt = 0

    max_gpu = 0

    hash.keys.sort.each{|addr|
      h = hash[addr]    
      row = []
      gpu_col = 0
      gpu_cnt = 0
      rows << [] if !row[row_cnt]
      
      h[:gpu].each_pair {|id,v|
        gpu_cnt = gpu_cnt + 1 # if gpu_cnt < gpu_row
        if gpu_col == gpu_row
          rows[row_cnt].concat row
          row_cnt = row_cnt + 1
          row = []
          rows.insert(row_cnt,row_headers.times.map{ ' ' })
          gpu_col = 0
          gpu_cnt = 1
          max_gpu = gpu_row
        end
        $id_format = "%-s"
        row.concat([
          sprintf("#{$id_format}",id),
          sprintf("#{$id_format}",speed_style(v[:gpu_speed].to_f.round(1))),
          sprintf("#{$id_format}",temp_style(v[:gpu_temp].to_i)),
          sprintf("#{$id_format}",fan_style(v[:gpu_fan].to_i))
        ])
        gpu_col = gpu_col + 1
        
      } # End every GPU
      rows[row_cnt].concat row
      row_cnt = row_cnt + 1
    
      if gpu_cnt > max_gpu
        max_gpu = gpu_cnt
      end
    }

    max_gpu.times {|i|
      headers.concat ['Id','Spd','Tmp','Fan']
    }
    return headers,rows
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

end
