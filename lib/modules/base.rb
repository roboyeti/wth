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
require 'lightly'

class Modules::Base
  using IndifferentHash  
  include SemanticLogger::Loggable
  include ModuleConsoleOutput
  include ModuleStructures

  attr_accessor :title, :store
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
    @store = p[:store] || {}

    @frequency  = @config["every"] || @config["default_frequency"] || 12
    @frequency  = 6 if @frequency < 6
    @port       = @config["port"] || 0
    @page       = @config["page"] || 1
    @extra      = @config["extra"] || ""
    @columns = []
    if @config["columns"] && !@config["columns"].empty?
      @columns = @config["columns"].split(',').map(&:to_i)
      @columns.unshift(0,1).uniq! #.sort
    end

    @dump       = @config["dump"] || false
    @coin       = @config["coin"] || ''
    @tor_host   = @config["tor_host"] || '127.0.0.1'
    @tor_port   = @config["tor_port"] || 9050
    @tor_socks  = @config["tor_socks"] || false
    @proxy      = @config["proxy"] || false
    @proxy_url  = @config["proxy_url"] || 'http://127.0.0.1:8080'
    @pending    = false

    # Internal variables
    @last_check     = Time.now - (@frequency*2)
    @last_check_ago = 0 #Time.now - @last_check

    @title    = 'Undefined???'
    @headers  = []
    @down     = {}
    @pending  = []
    @data     = Concurrent::Hash.new()
    @data[:addresses] = {}
    @data[:module]    = self.class.name
    @data[:last_check_ago] = @last_check_ago
    @events    = []
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

  #----------------- Hooks ------------------------
  def coin_value_dollars(*p)
    v = self.respond_to?(:coin_value_dollars_hook) ? coin_value_dollars_hook(*p) : 0
    sprintf("$%0.2f",v)
  end

  #----------------- Store ------------------------
  def store_it(key,value)
    if store
      store[key] = value
    end
  end

  def store_get(key)
    if store && !store.empty?
      store.key?(key) ? store[key] : nil
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

  #----------------- Output prep etc ------------------------
  def out_headers
    !@columns.empty? ? @headers.values_at(*@columns).dup : @headers.dup
  end

  def tableize(data,&block)
    title = nice_title_with_timer
    rows = []
    tables = []
    formats = []
    hdr_cnt = out_headers.count
    headers = out_headers

    data.keys.sort.each{|addr|
      item = data[addr]

      if item.state == "down"
        row = [ colorize(item.name.capitalize,$color_alert), colorize("Down!",$color_alert) ]
        (hdr_cnt -2).times{ row << '' }
        row = [ row.join(' ') ] if standalone?
        rows << row
      elsif item.state =~ /^pending/
        row = [ colorize(item.name.capitalize,$color_warn), colorize("Pending...",$color_warn) ]
        (hdr_cnt -2).times{ row << '' }
        row = [ row.join(' ') ] if standalone?
        rows << row
      elsif block_given?
        yield(item,rows,formats,headers)
      else
        row = []
        item.each_pair{|k,v| row << v }
        rows << row
      end

    }
    if !@columns.empty?
      formats.map!{|format| format.values_at(*@columns) }
      rows.map!{|row| row.values_at(*@columns).compact }
    end

    Struct.new(:title, :headers, :rows, :formats, keyword_init: true).new({
      title: title,
      headers: headers,
      rows: rows,
      formats: formats
    })
  end

  def table(p={})
#    @table ||= Struct.better(
OpenStruct.new({
        title: p[:title] || '',
        headers: p[:headers] || [],
        rows: p[:rows] || []
}) #.new(p)
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

  def nice_title_with_timer
    "#{nice_title} : Last Checked: #{data["last_check_ago"]} seconds ago"
  end

  def standalone?
    @standalone == 1 || @standalone == true || @standalone == 'true'
  end
  
  # Add event
  def add_error(addr,message)
    @events << pastel.red(sprintf("%-s : %s: %-22s: %-s",Time.now,self.class.name,addr,message))
  end
  # Add event
  def add_event(addr,message)
    @events << pastel.white(sprintf("%-s : %s: %-22s: %-s",Time.now,self.class.name,addr,message))
  end
  # Add event
  def add_warn(addr,message)
    @events << pastel.yellow(sprintf("%-s : %s: %-22s: %-s",Time.now,self.class.name,addr,message))
  end
  
  # Check all nodes provided in a module config.
  # Unwieldy and strange... need to demystify and unf*ck after so many changes
  #
  # More or less...
  # * Check if it is time to try a request (time rdy, no prior data, or data pending)
  # * iterate thru nodes
  # ** Catch errors ... handle with log and basic structure creation
  # ** Pending results get added to a check queue ... but any other hosts are
  #    forced checked again!!!! (ARG!)
  # ** Data stored to thread safe instance var
  # ** Set timer if needed...
  #
  def check_all
    clear_events
    @data[:addresses] ||= {}

    tchk = (Time.now - @last_check)
    lcl_last_check = @last_check
    lcl_last_check_ago = @last_check_ago

    if !@pending.empty? || @data.empty? || tchk > @frequency
      have_pending = !@pending.empty?
      nodes = @config['nodes'].keys.sort
      node = nil

      nodes.each {|nkey|
        @request_counter = 0

        nval = @config['nodes'][nkey]
        begin
          # If still down (under recheck frequency), mark it as such, update recheck counter, else we delete the down entry
          if @down[nkey] && (Time.now - @down[nkey]) < 60
            @data[:addresses][nkey] = down_handler(nkey,"Service recheck pending...")
            next
          else
            @down.delete(nkey)
          end
          
          logger.debug("Checking service #{nkey}")
          next if have_pending && !@pending.include?(nkey)

          node = check(nval,nkey)
          node.target = nval ? nval.split(':')[0] : nkey
          node.state == 'pending_update' ? @pending << nkey : @pending.delete(nkey)

          next if @data[:addresses][nkey] && node.state == 'pending_update'

          @data[:addresses][nkey] = node
          
        rescue => e
          logger.error("Service down #{nkey}", e)
          @down[nkey] = Time.now
          @data[:addresses][nkey] = down_handler(nkey,"Service down!",false,e)
        end

      }
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
    data.address  = data.name = addr
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

  # Quick and simple rest call with URL.
  def simple_rest(url,timeout=30,hdrs={})
    s = if proxy
          simple_proxy_request(url,timeout)
        elsif tor_socks
          OpenStruct.new({ body: simple_tor_request(url,timeout)})
        else
          RestClient::Request.execute(:method => :get, :url => url, :timeout => timeout, :headers => hdrs)          
        end
    res = s && s.body ? JSON.parse(s.body) : {}
    file = url.split('?')[0].split('://')[1].gsub('/','_')
    @dump && dump_response("#{file}_#{@request_counter}",["URL::#{url}",res])
    @request_counter += 1

    # Rescue on closed since we have better errors to catch...
    begin
      s.closed
    rescue
    end
    return res
  end

  def simple_proxy_request(url,timeout=30)
    return "{}" if @proxy_url.empty?
    RestClient::Request.execute(:method => :get, :url => url, :proxy => p_url, :headers => {}, :timeout => timeout)
  end

  # TODO: Add timeout!!!
  def simple_tor_request(url,timeout=30)
    return "" if @tor_host.empty?
    require 'socksify/http'
    uri = URI.parse(url)
    Net::HTTP.SOCKSProxy(@tor_host, @tor_port).get(uri)
  end

  def simple_http_request(url,timeout=30,hdrs={})
    res = RestClient::Request.execute(:method => :get, :url => url, :timeout => 60, :headers => hdrs)
    file = url.split('?')[0].split('://')[1].gsub('/','_')
    @dump && dump_response("#{file}_#{name}",["URL::#{url}",res])
    res.body
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
  
  #-------------------------- Various format helpers ----------------------

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

  def uptime_from_eseconds(time)
    uptime_seconds(Time.now - Time.at(time))
  end

  # Convert rfc3339 time format into a Time object
  def parse_rfc3339(time)
    DateTime.rfc3339(time).to_time  
  end
  
  # Nice format for Time instance output
  def nice_time(time)
    return '' if !time.is_a?(Time)
    time.localtime.strftime "%Y-%m-%d %H:%M:%S"
  end

  # Make keys in hash sane snake_case
  def fix_keys(hsh,*extra)
    new_hash = {}
    hsh.each_pair{|k,v|
      new_hash[fix_key(k,*extra)] = v
    }
    new_hash
  end

  # Make key (string) into a sane snake_case
  def fix_key(k,*extra)
    key = k.dup
    if !extra.empty?
      extra.each{|e|
        key.gsub!(e[0],e[1])
      }
    end
    key.gsub(/\W/,'').snakecase  
  end

  def private_address(addr)
    return '' if addr.blank?
    "#{addr[0..3]}...#{addr[-3..-1]}"
  end
end
