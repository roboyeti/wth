# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'json'
require 'pastel'
require 'terminal-table'
require 'concurrent'

class Base
  using IndifferentHash  

  attr_accessor :title
  attr_reader :config, :last_check, :frequency, :data, :port, :events, :page, :responses, :coin
 
  def initialize(p={})
    @config = p[:config] || {}
    @frequency = @config["every"] || @config["default_frequency"] || 12
    @port = @config["port"] || 0
    @page = @config["page"] || 1
    @coin    = @config["coin"] || ''
    @last_check = Time.now - (@frequency*2)
    @title = @config[:title] || 'Undefined???'
    @down = {}
    @data = Concurrent::Hash.new()
    @events = []
    @responses = {}
  end

  [:check, :console_out, :format].each {|m|
    # TODO - add error output for no default available...    
  } 

  # Caller should collect and clear per iteration
  def clear_events
    @events = []    
  end

  def nice_title
    if config['extra']
      "#{title} #{config['extra']}"
    elsif config['coin']
      "#{title} - #{config['coin']}"
    else
      title
    end
  end

  def standalone?
    @standalone == 1 || @standalone == true || @standalone == 'true'
  end
  
  # Add event
  def add_error(addr,message)
    @events << $pastel.red(sprintf("%-s : %-22s: %-s",Time.now,addr,message))
  end
  # Add event
  def add_event(addr,message)
    @events << $pastel.white(sprintf("%-s : %-22s: %-s",Time.now,addr,message))
  end
  # Add event
  def add_warn(addr,message)
    @events << $pastel.yellow(sprintf("%-s : %-22s: %-s",Time.now,addr,message))
  end
  
  # Check all nodes provided in a module config.
  #
  def check_all
    @events = []
    tchk = (Time.now - @last_check)

    if @data.empty? || tchk > @frequency
      out = []
      @data = OpenStruct.new({ addresses: {} })
      addresses = @config['nodes'].keys.sort
      
      addresses.each {|k|
        v = @config['nodes'][k]
        @data['addresses'][k] = {}
        begin
          # If still down (under recheck frequency), mark it as such, update recheck counter, else we delete the down entry
          if @down[k]
            if (Time.now - @down[k]) < 180
              @data[:addresses][k] = down_handler(k,"Service recheck pending...")
            else
              @down.delete(k)
            end
          end
          
          # We need to check again, since we may have deleted the down
          if !@down[k]
            h = self.check(v,k)
            @data['addresses'][k] = h
          end
          
        rescue => e
          @down[k] = Time.now
          @data[:addresses][k] = down_handler(k,"Service down!",false,e)
        end
      }
      @last_check = Time.now
    end

    @data[:last_check_ago] = (Time.now - @last_check).to_i
    @data
  end

  def down_handler(addr,message,countdown=true,error=nil)    
    message = if countdown
      "#{message} ;; Checked @ #{@down[addr]} ;; #{(Time.now - @down[addr]).round(2)} seconds ago"    
    else
      check_time = (180 - (Time.now - @down[addr]))
      "#{message} ;; Checked @ #{@down[addr]} ;; Checking in #{check_time.round(2)} seconds."
    end
        
    data = structure
    data.down     = true
    data.message  = message
    data.time     = Time.now
    data.addr = data.name = addr

    if error
      data.backtrace  = error.backtrace[0..4],
      data.error      = error,
      add_error(addr,"#{error} #{error.backtrace[0]}")
      add_error(addr,message)
    else
      add_warn(addr,message)
    end
    
    data
  end
  
  # Quick and simple rest call with URL.
  # TODO: Get timeout working. Execute needs trouble shooting or gem replaced...
  def simple_rest(url,timeout=10)
#    s = if proxy
#          RestClient::Request.execute(:method => :get, :url => url, :proxy => proxy, :headers => {}, :timeout => timeout)
#        else
    s = RestClient::Request.execute(:method => :get, :url => url, :headers => {}, :timeout => timeout)          
#        end
#    s = RestClient.get url
    res = s && s.body ? JSON.parse(s.body) : {}
    begin
      s.closed
    rescue
    end
    res
  end

  # Structure of GPU workers
  def node_structure
    OpenStruct.new({
      name: "",
      address: "",
      miner: "",
      uptime: 0,
      algo: "",
      coin: "",
      pool: "",
      difficulty: 0,
      combined_speed: 0,
      total_shares: 0,
      rejected_shares: 0,
      invalid_shares: 0,
      power_total: 0,
      time: Time.now,
      gpu: {},
      cpu: cpu_structure,
      system: {},
    })
  end

  def worker_structure
    node_structure
  end  
  def structure
    node_structure
  end  


  # Structure of GPU data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_structure
    OpenStruct.new({
      :pci        =>"0",
      :id         =>0,
      :gpu_speed  =>0.0,
      :gpu_temp   =>0,
      :gpu_fan    =>0,
      :gpu_power  =>0,
      :speed_unit =>""
    })
  end

  # Structure of GPU device data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_device_structure
    OpenStruct.new({
      :pci        =>"0",
      :id         =>0,
      :gpu_temp   =>0,
      :gpu_fan    =>0,
      :gpu_power  =>0,
    })
  end

  def cpu_structure
    OpenStruct.new({
      :name       =>"",
      :id         =>0,
      :cpu_temp   =>0,
      :cpu_fan    =>0,
      :cpu_power  =>0,
      :threads_used =>0,
    })
  end
  
  # Try to clean up CPU text ...
  #
  def cpu_clean(cpu)
    cpu.gsub!(/\(.+\)|\@|Processor|\s$/,'')
    cpu.gsub!(/\s+/,' ')
    cpu.gsub!(/$\s/,'')
    cpu.chomp!
    cpu.chomp!
    cpu
  end

  # Take uptime in seconds and convert to d/h/m format
  #
  def uptime_seconds(time)
    time = time.to_f
    if time > 86400
      sprintf("%.2fd",(time / 86400))
    elsif time > 3600
      sprintf("%.2fh",(time / 3600))
    else
      sprintf("%.2fm",(time / 60))
    end
  end

  # Take uptime in minutes and convert to d/h/m format
  #
  def uptime_minutes(time)
    uptime_seconds(time.to_f * 60)
  end
  
  # Output a console table
  def table_out(headers,rows,title=nil)
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
        t.style.width = 60
      end
      t.title = title if title
    end

    rows.each {|r|
      if r.count < max_col
        (max_col - r.count).times {|i| r << ''}
      end
      table << r.map{|c|
        colorize(c,$color_row)        
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
      tarr[idx] = colorize( sprintf("%-#{len}s",tarr[idx]),$color_standalone_title)
      idx = idx + 1
    end
    tarr.delete_at(idx + 1)
    tarr[idx].gsub!(/[\||\│]/,' ')
    tarr[idx] = no_colors(tarr[idx])
    diff = len - tarr[idx].length
    tarr[idx] = colorize("#{tarr[idx]}#{' '*diff}",$color_header)
    tarr.map!{|t|
      t.gsub("│",colorize("│",$color_divider))
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
      colorize(value,$color_red)
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
  
  def colorize(val,colors)
    m = $pastel
    arc = *colors
    arc.each {|c|
      m = m.send(c)
    }
    m.detach.(val)
  rescue
    val
  end
  
  def no_colors(s)
    s.gsub /\e\[\d+m/, ""
  end

  
end
