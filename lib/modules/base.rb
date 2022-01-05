# Author: BeRogue01
# License: See LICENSE file
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'json'
require 'pastel'
require 'terminal-table'
require 'concurrent'
require 'pp'

class Modules::Base
  using IndifferentHash  
  include SemanticLogger::Loggable

  attr_accessor :title
  attr_reader :config, :last_check, :last_check_ago, :frequency, :data, :port, :events, :page, :responses, :coin, :proxy, :config_options, :tor_socks, :title

  @api_names = []  

  def self.api_names
    @api_names
  end

  def api_names
    self.class.api_names
  end

  def initialize(p={})
    # Configuration set values
    @config = p[:config] || {}
    @store = p[:store] || nil

    @frequency = @config["every"] || @config["default_frequency"] || 12
    @frequency = 6 if @frequency < 6
    @port = @config["port"] || 0
    @page = @config["page"] || 1
    @extra = @config["extra"] || ""

    @dump = @config["dump"] || false
    @coin    = @config["coin"] || ''
    @tor_host = @config["tor_host"] || '127.0.0.1'
    @tor_port = @config["tor_port"] || 9050
    @tor_socks = @config["tor_socks"] || false
    @proxy = @config["proxy"] || false
    @proxy_url = @config["proxy_url"] || 'http://127.0.0.1:8080'
    @pending = false

    # Internal variables
    @last_check = Time.now - (@frequency*2)
    @last_check_ago = 0 #Time.now - @last_check

    @title = 'Undefined???'
    @down = {}
    @pending = []
    @data = Concurrent::Hash.new()
    @data[:address] = {}
    @data[:module] = self.class.name
    @data[:last_check_ago] = @last_check_ago
    @events = []
    @responses = {}
    @config_options = {}

    register_config_option("every",12,[],"Number of seconds between checks.  Minimum 6 seconds. Set carefully, as a low value might put a lot of load on your systems or remote APIs.")
    register_config_option("page",1,[],"Optional page # to display on.")
    register_config_option("dump",false,[true,false],"Optional value to have module dump the raw remote requests into temp dir.  May not always be functional in a module.")
    register_config_option("coin",'',[],"Optional, but recommended value of the coin symbol the module is related to.  This is used as a helper for things like prfit/revenue calculations.")
    register_config_option("port",0,[],"Default port # of remote service.  Can be also specified per node in the nodes list.")
#    register_config_option("proxy",'',[],"Enables proxy calls.  Uses a proxy_list.  Caution, this should never be used with authentication data.")
#    register_config_option("proxy_url",'',[],"Enables proxy calls via a user defined proxy.")

    logger.info("Loaded module")
  end

  def register_config_option(name,default,options,description)
    @config_options[name] = {
      :name => name,
      :default => default,
      :options => options,
      :description => description,
    }
    @config_options
  end

  [:check, :console_out, :format].each {|m|
    # TODO - add error output for no default available...    
  } 

  #----------------- Hooks ------------------------
  def coin_value_dollars(*p)
    v = self.respond_to?(:coin_value_dollars_hook) ? coin_value_dollars_hook(*p) : 0
    sprintf("$%0.2f",v)
  end

  #----------------- Store ------------------------
  def store_it(key,value)
    if store && !store.empty?
      store[key] = value
    end
  end

  def store_get(key)
    if store && !store.empty?
      store[key]
    end
  end

  #----------------- Maintenance Calls ------------------------

  # Caller should collect and clear per iteration
  def clear_events
    @events = []    
  end

  def clear_down
    @down = {}
  end
  
  def nice_title
    if config['extra']
      "#{title}: #{config['extra']}"
    elsif config['coin']
      "#{title}: #{config['coin']}"
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
    lcl_last_check = @last_check
    lcl_last_check_ago = @last_check_ago

    if !@pending.empty? || @data.empty? || tchk > @frequency
      addresses = {}
      address_list = @config['nodes'].keys.sort
      
      address_list.each {|k|
        v = @config['nodes'][k]
        addresses[k] = {}
        begin
          # If still down (under recheck frequency), mark it as such, update recheck counter, else we delete the down entry
          if @down[k]
            if (Time.now - @down[k]) < 60
              addresses[k] = down_handler(k,"Service recheck pending...")
            else
              @down.delete(k)
            end
          end
          
          # We need to check again, since we may have deleted the down
          if !@down[k]
            logger.debug("Checking service #{k}")
            h = self.check(v,k)
            if h.state == 'pending_update'
              @pending << k
            else
              @pending.delete(k)
            end
            if @data[:addresses] && @data[:addresses][k] && h.state == 'pending_update'
              addresses[k] = @data[:addresses][k]
            else
              h["target"] = v
              addresses[k] = h
            end
          end
          
        rescue => e
          logger.error("Service down #{k}", e)
          @down[k] = Time.now
          addresses[k] = down_handler(k,"Service down!",false,e)
        end

      }
      @data[:addresses] = addresses
      @last_check = Time.now
    end

    if @pending.empty?
      lcl_last_check_ago = (Time.now - @last_check).to_i
    else
      @last_check = lcl_last_check
      lcl_last_check_ago = 0
    end

    @last_check_ago = @data[:last_check_ago] = lcl_last_check_ago #(Time.now - @last_check).to_i #lcl_last_check_ago
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
    data.addr     = data.name = addr
    data.state    = 'down'

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

  # TODO: Add timeout!!!
  def proxy_request(url,timeout=30)
    return "{}" if @proxy_url.empty?
    RestClient::Request.execute(:method => :get, :url => url, :proxy => p_url, :headers => {}, :timeout => timeout)
  end

  # TODO: Add timeout!!!
  def tor_request(url,timeout=30)
    return "" if @tor_host.empty?
    require 'socksify/http'
    uri = URI.parse(url)
    Net::HTTP.SOCKSProxy(@tor_host, @tor_port).get(uri)
  end

  # Quick and simple rest call with URL.
  def simple_rest(url,timeout=30)
    s = if proxy
          proxy_request(url,timeout)
        elsif tor_socks
          OpenStruct.new({ body: tor_request(url,timeout)})
        else
          RestClient::Request.execute(:method => :get, :url => url, :headers => {}, :timeout => timeout)          
        end
    res = s && s.body ? JSON.parse(s.body) : {}
    file = url.split('?')[0].split('://')[1].gsub('/','_')
    @dump && dump_response(file,["URL::#{url}",res])

    begin
      s.closed
    rescue
    end
    return res
  end

  # Dump data to tmp file
  def dump_response(file,data)
    file = "#{self.class.name}_#{file}.txt"
    file.gsub!(/[\:|\.]/,'_')
    File.open("./tmp/#{file}", "w+") {|f|
      f << "Class::#{self.class.name}\n"     
      data.each{|d|
        if d.is_a?(String)
          f << "#{d}\n"
        else
          PP.pp(d,f)
        end
      }
    }
  end

  def module_structure
    OpenStruct.new({
      module: self.class.name,
      name: name,
      addresses: {},
    })
  end

  def root_structure
    OpenStruct.new({
      name:     "",
      address:  "",
      time:     Time.now,
      state:    "",
    })
  end

  # Structure of GPU workers
  def node_structure
    OpenStruct.new({
      name:     "",
      address:  "",
      miner:    "",
      user:     "",
      uptime:   0,
      algo:     "",
      coin:     "",
      pool:     "",
      difficulty:     0,
      combined_speed: 0.0,
      total_shares:   0,
      rejected_shares: 0,
      stale_shares:   0,
      invalid_shares: 0,
      power_total:    0,
      revenue:        0.0,
      target:   "",
      time:     Time.now,
      gpu:      {},
      cpu:      cpu_structure,
      system:   {},
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
      pci: "0",
      id: 0,
      gpu_speed: 0.0,
      gpu_temp: 0,
      gpu_fan: 0,
      gpu_power: 0,
      speed_unit: "",
      total_shares: 0,
      rejected_shares: 0,
      stale_shares: 0,
      invalid_shares: 0,
    })
  end

  # Structure of GPU device data
  # * GPU power may not be available
  # * id may not match "system" id.  PCI bus id is more reliable.
  def gpu_device_structure
    OpenStruct.new({
      pci:        "0",
      id:         0,
      card:       "",
      gpu_temp:   0,
      gpu_fan:    0,
      gpu_power:  0,
      core_clock: 0,
      memory_clock: 0,
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
  
  def no_colors(s)
    s.gsub /\e\[\d+m/, ""
  end

  def parse_rfc3339(time)
    DateTime.rfc3339(time).to_time  
  end
  
  def nice_time(time)
    return '' if !time.is_a?(Time)
    time.localtime.strftime "%Y-%m-%d %H:%M:%S"
  end

  def fix_keys(hsh,*extra)
    new_hash = {}
    hsh.each_pair{|k,v|
      new_hash[fix_key(k,*extra)] = v
    }
    new_hash
  end

  def fix_key(k,*extra)
    key = k.dup
    if !extra.empty?
      extra.each{|e|
        key.gsub!(e[0],e[1])
      }
    end
    key.gsub(/\W/,'').snakecase  
  end

end
