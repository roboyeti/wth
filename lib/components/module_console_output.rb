module ModuleConsoleOutput
  load 'templates/pool_summary.rb'
  load 'templates/gpu_worker.rb'
  load 'templates/table.rb'

  def standalone? ; false; end

  def console_out(data=@data)
    tables = *tableize(data["addresses"])
    tables.map{|struct|
      table_out(struct.headers,struct.rows,struct.title,struct.formats)
    }
  end

  # Return a console table
  def table_out(headers,rows,title=nil,formats=[])
    max_col = 1
    rows.each {|row|
      max_col = row.count if row.is_a?(Array) && row.count > max_col
    } 

    div = "│" #colorize("│",$color_divider)
    table = Terminal::Table.new do |t|
      t.headings = headers
      t.style = {
        :border_left => false, :border_right => false,
        :border_top => false, :border_bottom => false,
        :border_y => div,
        :padding_left => 0, :padding_right => 0,
        :border_x =>"─" , :border_i => "┼",
      }      
      if standalone?
# Actually throws a freaking error if it can't do it...
#        t.style.width = 140
      end
      t.title = title if title
    end

    rows.each_with_index {|r,ridx|
      if r.count < max_col
        (max_col - r.count).times {|i| r << ''}
      end
      table << r.map.with_index{|c,idx|
        if formats[ridx] && formats[ridx][idx]
          colorit(c,formats[ridx][idx])
        else
          colorit(c,$color_row)
        end
      }      
    }

    # Go thru all columns to set alignment because setting it
    # in new overrides individual columns
    table.columns.count.times{|col|
      ori = col == 0 ? :left : :right
      table.align_column(col, ori)
    }
    
    tout = table.render
    tarr = tout.split("\n")
    idx = 0
    len = tarr[1] ? tarr[1].length + 1 : 0

    if title
      tarr.delete_at(idx + 1)
      tarr[idx] = colorit( sprintf("%-#{len}s",tarr[idx]),$color_standalone_title)
      idx = idx + 1
    end
    tarr.delete_at(idx + 1)
    if tarr[idx]
      tarr[idx].gsub!(/[\||\│]/,' ')
      tarr[idx] = no_colors(tarr[idx])
      diff = len - tarr[idx].length
      tarr[idx] = colorit("#{tarr[idx]}#{' '*diff}",$color_header)
    end
    tarr.map!{|t|
      t.gsub("│",colorit("│",$color_divider))
    }
    tout = tarr.join("\n")
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

  # Color and style the power value
  #
  def format_power(v)
    "#{v.to_f.round}w"
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

  # Colorize for simple threshold ... kind of lame... mileage may vary...
  #
  # @params [Numeric] value What you need to compare and color 
  # @params [String] comparator Comparators: "<","<=",">",">=","=="
  # @params [Numeric] warn_value Value for yellow color
  # @params [Numeric] alert_value Value for red color
  #
  def colorize_simple_threshold(value,comparator,warn_value,alert_value)
    if eval("#{value} #{comparator} #{alert_value}")
      colorize(value,$color_alert)
    elsif eval("#{value} #{comparator} #{warn_value}")
      colorize(value,$color_warn)
    else
      colorize(value,$color_ok)
    end      
  end
  
  # Colors s2
  def colorize_percent_of(s1,s2,pwarn,palert)
    color_str = if s2 > (s1 * palert)
      $color_alert     
    elsif s2 > (s1 * pwarn)
      $color_warn
    else
      $color_ok
    end
    colorize(s2,color_str)
  end

  # Colors s2
  def colorize_above_below(s1,value,round=nil)
    color_str = if s1 == value
      ""
    elsif s1 > value
  	  $color_ok
    else
      $color_alert
    end
    s1 = sprintf("%.#{round}f",s1) if round
    colorize(s1,color_str)
  end
  alias_method :colorize_around, :colorize_above_below
  
  def colorobj
    @pastel ||= Pastel.new
  end
  alias_method :pastel, :colorobj

  def colorizer(colors)
    m = colorobj
    arc = *colors
    arc.each {|c|
      m = m.send(c)
    }
    lambda{|v| m.detach.(v)}
  end
  
  def colorize(val,colors)
    m = colorobj
    arc = *colors
    arc.each {|c|
      m = m.send(c)
    }
    m.detach.(val)
  rescue
    val
  end
  alias_method :colorit, :colorize

  def no_colors(s)
    s.gsub /\e\[\d+m/, ""
  end


end