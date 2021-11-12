# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#

class GpuBase < Base
  using DynamicHash
  
  attr_reader :header_length, :gpu_row
 
  def initialize(p={})
    super
    @standalone = @config["standalone"]
    @gpu_row    = @config["gpu_row"] || 5
  end
      
  # General console out creation.
  # See 'templates/gpu_worker.rb' and 'templates/table.rb' for magic global style stuff
  def console_out(data)
    hosts = data['addresses']
    rows = []
    max_gpu = 0 # Track largest number of GPU per row
    
    # TODO: Get from confg
    headers = ["#{title}:#{config['extra']}",'Uptime','Speed','Power','Shares','Rjct']
    
    hosts.keys.sort.each{|addr|
      h = hosts[addr]

      if h["down"] == true
        h["name"] = addr
        h[:uptime] = colorize("down",$color_alert)
        h[:combined_speed] = 0
        @events << $pastel.red(sprintf("%s : %22s: %s",Time.now,addr,h["message"]))
        h[:gpu] = {}
      end

      rows << [
        standalone? ? '' : h["name"].capitalize,
        h[:uptime],
        h[:combined_speed].round(0),
        format_power(h[:power_total]),
        h[:total_shares],
        h[:rejected_shares]
      ]
    }

    if standalone?
      k = hosts.keys.sort.first
      o = table_out(headers,rows,hosts[k]["name"].upcase)
      gheaders = []
      grows = []
      gpu_grid(hosts,gheaders,grows)
      o << table_out(gheaders,grows)
      o
    else
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

  # Color and style the power value
  #
  def format_power(v)
    "#{v.to_f.round}w"
  end

  # Color and style the speed value
  #
  def speed_style(speed)
    str = sprintf("%2s","#{speed}#{$speed_sym}")
    #sprintf("%3s#{$speed_sym}",speed)
    if (speed <= 0)
      colorize(str,$color_speed_alert)
    else
      colorize(str,$color_speed_ok)      
    end     
  end

  # Color and style the fan value
  #
  def fan_style(fan)
    fan_str = sprintf("%2s","#{fan}#{$fan_sym}")
    #sprintf("%3s#{$fan_sym}",fan)
    
    if (fan > $fan_alert) || (fan <= 0)
      colorize(fan_str,$color_fan_alert)
    elsif fan > $fan_warn
      colorize(fan_str,$color_fan_warn)          
    else
      colorize(fan_str,$color_fan_ok)      
    end     
  end

  # Color and style the temp value
  #
  def temp_style(temp)
    temp_str = sprintf("%2s","#{temp}#{$temp_sym}")
    #sprintf("%3s#{$temp_sym}",temp)
    if ( temp > $temp_alert ) || (temp <= 0)
      temp = colorize(temp_str,$color_temp_alert)
    elsif temp > $temp_warn
      temp = colorize(temp_str,$color_temp_warn)
    else
      temp = colorize(temp_str,$color_temp_ok)
    end
  end

end
