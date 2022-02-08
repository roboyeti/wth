# Author: BeRogue01
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Core class for WTH.
#
# TODO: Move config bits all to module to clean up core code.  Med priority
# TODO: Make some decisions about how much of this needs to be moved to modules, with the goal
#       of different cores being possible.  Low priority.
require 'rest-client'
require 'yaml'
require 'json'
require 'socket'
require 'os'
require 'sys/cpu'
require 'lucky_case/string'
require 'bigdecimal'
require 'pastel'
require 'securerandom'

load './lib/components/web_server_basic.rb'
load './lib/modules/include_list.rb'

@modules_autoload_list.each{|mod|
  load "./lib/modules/#{mod}"
}

[ 'plugin_base'].each{|mod|
  load "./lib/plugins/#{mod}.rb"
}

# Config related methods
class Core
  using IndifferentHash  
  include WthConfig
  include WthConsole
  include Sys
  include SemanticLogger::Loggable
  
  VERSION = "0.19i"
  CONFIG_VERSION = 20211103
  @MODULES = []

  # Map from config entry to plugin class
  PLUGINS = {
    'conemu' => 'ConEmu',
    'con_emu' => 'ConEmu',
    'what_to_mine' => 'WhatToMine',
    'coin_gecko' => 'CoinGecko',
  }.freeze

  attr_accessor :verbose, :current_page
  attr_reader :config_file, :cfg, :module_instances, :plugins, :console_out, :os, :show_revenue
  
  # TODO: Document
  def initialize(p={})
    @config_file = p["config"] || p["config_file"] || "wth_config.yml"
    @config_type = "yml"
    @verbose = p["verbose"] || false
    set_module_config_version(CONFIG_VERSION)
    check_and_rotate_log('wth.log')

    @cfg = load_config(@config_file)
    @console_out = @cfg["console_out"] ? true : false
    @page_titles = []
    if config["pages"]
      config["pages"].each_pair{|pn,pt|
        @page_titles[pn.to_i - 1] = pt
      }
    end
    @show_revenue = @cfg["revenue_banner"] || false
    @current_page = @cfg["start_page"] || 1
    @header_short = @cfg["header_short"] ? true : false
    @store = Concurrent::Hash.new()
    @log = {}
    @modules = {}
    @module_instances = {}
    @os = OS
    @plugins = {}
    os_init
    $app = self
  end

  # Config and core version stuff
  #
  def version ; VERSION ; end

  # Service Start
  # Easy startup for WTH
  #
  def start
    init_plugins(config["plugins"])
    init_wth_modules(config['modules'])
    @cfg["web_server_start"] && webserver_start      
    sleep(2)
    if @cfg["console_out"]
      logger.info("WTH started with console.")
      init_key_reader
    else
      logger.info("WTH started without console.")
      puts "WTH started.  Will not detach from console in MS Windows."    
    end
  end

  # Pulse the service, letting it do one round of work
  def pulse
    check_and_rotate_log('wth.log')
#    @cfg["web_server_start"] && app.webserver_pulse(page_out)
  end

  # Load basic "template" files
  # Not really full templates yet...
  # Should be watched for changes and re-loaded
  def load_templates
    load 'templates/pool_summary.rb'
    load 'templates/gpu_worker.rb'
    load 'templates/table.rb'
  end

  # Returns config hash, loading default one if needed.
  #
  # @returns Hash
  #
  def config
    @cfg ||= load_config(@config_file)
  end

  # There is a newer version of the config format
  # TODO: Maybe not going to work out.
  #
  def newer_config_version?
    current_config_version < module_config_version  
  end
    
  # Load or create/save/load template config file.  Sets and return config hash.
  #
  # @param String file Optional file, default uses config_file
  # @returns Hash
  #
  def load_config(file=config_file)
    puts "Loading config file #{file}..."
    cfg = File.file?(file) ? load_yaml(file) : ''

    if cfg.empty?
      fail("No such config file #{file}.  Please copy wth_example_config.yml to wth_config.yml and edit it.")
#      puts "No config file found or is empty. Saving template config to '#{file}'..."
#      cfg = YAML.load(template_config)
#      dump_config(cfg,file)
    else
      puts "Configuration loaded..."
    end

#   if cfg["version"] < module_config_version
#     STDERR.puts "There is a newer version of the configuration format than what your config file is using."
#   end
#    YAML.load(template_config).merge!(cfg)
#    logger.info("Loaded from config file: #{file}")
    cfg
  rescue => e
    logger.error("Unknown error loading config file '#{file}'",e)
    puts "Unknown error loading config file '#{file}': #{e}"
    {}
  end
  
  def save_config(file=config_file,hash=cfg)
    hash["version"] = CONFIG_VERSION if newer_config_version?
    dump_config(hash,file)
  end

  # Load YAML file.
  #
  # @param String file Optional file, default uses config_file
  # @returns Hash
  #  
  def load_yaml(file=config_file)
    fail("File #{file} doesn't exist!") if !File.file?(file)
    YAML::load_file(file)
  rescue JSON::ParserError => e
    fail %Q{
      Config file has an error.
      Possibly caused by missing commas, extra comma without following entity, unclosed quotes.
      Error: #{e.to_s[0..255]}
    }
  end

  # Load JSON file.
  #
  # @param String file Optional file, default uses config_file
  # @returns Hash
  #
  def load_json(file)
    fail("File #{file} doesn't exist!") if !File.file?(file)
    data = ''
    File.open(file) do |f|
      data << f.read
    end
    JSON.parse(data)
  rescue JSON::ParserError => e
      fail %Q{
    Config file has an error.
    Possibly caused by missing commas, extra comma without following entity, unclosed quotes.
    Error: #{e.to_s[0..255]}
    }
  end
  
  # Save config to JSON.
  #
  # @param String file Optional file, default uses config_file
  # @param Hash hash Optional hash to save, default is config/cfg.
  # @returns Boolean
  #
  def save_json(file=config_file,hash=cfg)
    File.open(file, "w+") do |f|
      f << JSON.pretty_generate(hash)
    end
  end

  def check_rotate_log?(log_file)
    File.new(log_file,"w+") if (!File.exist?(log_file))    
    File.size(log_file) > 10000000
  end

  def check_and_rotate_log(log_file)
    rotate_log(log_file) if check_rotate_log?(log_file)
  end
  
  def rotate_log(log_file)
    SemanticLogger.flush
    FileUtils.cp(log_file, "#{log_file}.bck")
    File.new(log_file,"w+")
    SemanticLogger.reopen
#    File.truncate(log_file, 0)
  end
  
  # Add to a "log" stream.  This provides in memory, short
  # queue of logs of the "type" specified.
  #
  def add_log(type,val)
    @log[type] ||= []
    @log[type] << val
    @log[type].shift( @log[type].length - 30 ) if @log[type].length > 30
    if @webserver
      @webserver.write_html_file(type,type.downcase.capitalize,@log[type])
    end
  end
  
  # Retrieve the logs of a 'type'
  # @return [Array] Some logs, yo
  #
  def get_log(type)
    @log[type] ||= []    
  end

  # Clears the logs of a 'type'
  # @return [Array] Some logs, yo
  #
  def clear_log(type)
    @log[type] = []    
  end

  # Dynamic load and init plugins
  #
  # @param [Hash] cfg The config section for plugins
  #
  def init_plugins(cfg=nil)
    cfg ||= config["plugins"]
    return nil if !cfg
    cfg.each_pair{|k,v|
      next if !PLUGINS[k]
      init_plugin(k,v)
    }
    plugins
  end

  def init_plugin(name,cfg={})
    return nil if !PLUGINS[name]
    file = PLUGINS[name].snake_case
    puts "Loading Plugin: #{name} => #{file}"
    load "./lib/plugins/#{file}.rb"
    obj = PLUGINS[name].constantize
    puts "Init Plugin: #{name} => #{obj.name}"
    @plugins[name] = obj.new(cfg)    
  end

  def self.modules=(ar)
    @MODULES = ar
    setup_modules
    @MODULES
  end

  def self.modules
    @MODULES
  end

  def modules
    self.class.modules
  end

  def self.setup_modules
    @MODULE_MAP ||= {}
    @MODULE_NAME_MAP ||= {}

    modules.each{|ma|
      mkey = ma[0]
      mdir = ma[1]
      mnames = ma[2..]
      @MODULE_MAP[mkey] = {
        'name' => mkey,
        'dir' => mdir,
        'file' => "./lib/modules/#{mdir}/#{mkey.snake_case}",
        'names' => mnames
      }
      mnames.each{|mn|
        @MODULE_NAME_MAP[mn] = @MODULE_MAP[mkey]
      }
    }
  end

  def self.get_module(key)
    @MODULE_NAME_MAP || setup_modules
    if @MODULE_NAME_MAP[key]
      @MODULE_NAME_MAP[key]
    end
  end

  def get_module(key)
    self.class.get_module(key)
  end

  # Check module has nodes and exists
  #
  def check_wth_module?(name,cfg)
    api = cfg['api']
    #!cfg["nodes"].empty? &&
    get_module(api)
  end
  
  # Dynamic load and init a module
  #
  # @param [Hash] cfg The config section for a module
  #
  def init_wth_module(name,cfg)
    cfg["default_module_frequency"] = config["default_module_frequency"]
    api = cfg['api']
    mod = get_module(api)
    file = mod["file"]
    puts "Loading Module: #{name} => #{mod["name"]} => #{file}"
    load "#{file}.rb"
    obj = "Modules::#{mod["name"]}".constantize
    puts "Init Module: #{name} => #{obj.name}"
    obj = @module_instances[name] = obj.new(config: cfg.merge({name: name}), store: @store)
    plugins.each_pair{|p,e|
      e.register.each_pair{|m,t|
        if obj.respond_to?(m)
          puts "#{e} plugs #{name}.#{m}()!" if verbose
          obj.define_singleton_method("#{m}_hook") {|*p| e.send(t,*p) }
        end
      }
    }
    obj
  end
  
  def init_cfg_module(name)
    cfg = config["modules"][name]
    return nil if !cfg
    init_wth_module(name,cfg)
  end
  
  # Dynamic load and init modules
  #
  # @param [Hash] cfg The config section for modules
  #
  def init_wth_modules(h_mods=nil)
    h_mods ||= config["modules"]
    return nil if !h_mods
    h_mods.each_pair {|m,p|
      init_wth_module(m,p) if check_wth_module?(m,p)  
    }
    true
  end

  def init_cfg_modules()
   init_wth_modules(config["modules"])
  end

  # Run modules to populate data, unthreaded, no output
  #
  # @return [Array] The pages to render form module pulse
  #
  def data_run_modules
    load_templates

		page_out = 10.times.map{|| []}
		module_instances.each_pair {|k,v|
      v.check_all
      v.events.each {|event| add_log('events',event) }
      v.clear_events
    }      
    true
  end
  
  # Run modules, unthreaded
  #
  # @return [Array] The pages to render form module pulse
  #
  def run_wth_modules
    load_templates

		page_out = 10.times.map{|| []}
		module_instances.each_pair {|k,v|
      begin
        a = v.console_out(v.check_all)
        c = a.is_a?(Array) ? a : a.split("\n")
        c << ""
      rescue => e
        add_log('events',"#{k} :: Output processing error: #{e} #{e.backtrace[0]}")
        logger.error("#{k} :: Output processing error",e)
        c << pastel.bright_red("#{k} - Error generating output.  See logs.")
        c << ""
      end
      page = (v.page || 1) - 1
      page_out[page] ||= []
      c.each {|l| page_out[page] << l }
      v.events.each {|event| add_log('events',event) }
      v.clear_events
    }      
		page_out
  end

  # Run modules, threaded
  # TODO: Needs to be improved upon ... a lot
  # TODO: Consolidate code with non-threaded method
  #
  # @return [Array] The pages to render form module pulse
  #
	def thread_wth_modules
		threads = []
    module_instances.each_pair {|k,v|
			thread = Thread.new {
          ['TERM', 'INT'].each do |signal|
            trap(signal){ exit; }
          end

          load_templates
          Thread.current.name = "#{self.class.name}:#{k}"
          Thread.current["me"] = v
          c = []
          begin
            a = v.console_out(v.check_all)
            c = a.is_a?(Array) ? a : a.split("\n")
            c << ""
          rescue => e
            add_log('events',"#{k} :: Output processing error: #{e} #{e.backtrace[0]}")
            logger.error("#{k} :: Output processing error",e)
            c << pastel.bright_red("#{k} - Error generating output.  See logs.")
            c << ""
          end
					Thread.current["mypage"] = c
					Thread.current["events"] = v.events
					v.clear_events
			}
			thread.abort_on_exception = true
			threads << thread
    }
		page_out = 10.times.map{|| []}
#		while !threads.empty?
      threads.each_with_index {|thr,idx|
#        thr = t.join(0.25);
        thr.join
        if thr
          page = (thr["me"].page || 1) - 1
          page_out[page] ||= []
          thr["mypage"].each {|l| page_out[page] << l }    
          thr["events"].each {|event| add_log('events',event) }
          thr.exit
#          threads.delete(idx)
        end
      }
#    end
		page_out
	end

  def daily_income
    module_instances.sum{|k,v| v.daily_income }
  end

  def monthly_income
    module_instances.sum{|k,v| v.monthly_income }
  end

  def has_events?
    module_instances.any?{|k,v| !v.events.empty? }
#    !@log['events'].blank? && @log['events'].count > 0
  end

  def clear_all_events
    module_instances.each_pair {|k,v|
      v.clear_events
    }
    clear_log('events')
  end

  def clear_all_down_nodes
    module_instances.each_pair {|k,v|
      v.clear_down
    }
    @down_reset = true
  end
  
  def down_reset?
    @down_reset ||= false
  end
  
  def down_reset_clear
    @down_reset = false
  end
  
  # Start web server
  # TODO: Enable port setting in config
  # TODO: Allow set IP to localhost only
  # TODO: Abstract in plugin
  #
  # @param [Integer] port The port to run service on.
  def webserver_start
    @webserver = WebServerBasic.new({
        :version => version
    }.merge(config["web_server"]))
    puts "Loading web server on port# #{@webserver.port}"
    @webserver.start
    @webserver.write_html_file('events','Events',"Nothing to show")
    @webserver.write_html_file('web_logs','Web Logs',"Nothing to show")    
    wout = []
    web_cmd_list.each{|c| wout << sprintf("%10s%-s",'',c) }
    wout << "\n"
    @webserver.write_html_file('command_list','Commands',wout)
    logger.info("WTH web service started on port: #{@webserver.port}")
    @webserver
  end
  
  # Do some webserver work.
  # - Read webserver access log and add_log
  # - Start a thread to write html pages
  # TODO: Needs some work
  #
  # @param [Array] pages Page data to render to html files
  #
  def webserver_pulse(pages)
    return nil if !@webserver
    # Non blocking read on webserver output to web access log
    while io = @webserver.read_io_nonblock
      add_log('web_logs',io)
    end
    Thread.new{
      @webserver.write_html(page_titles,pages)
    }
  end
  
  # Terminal write file.  Rename ... geez
  #
  def write_file(file,out)
    ff = File.open(file, 'w')
    ff.write(Terminal.render(out.join("\n")))
    ff.close
  end

  def page_title(page)
    idx = page - 1
    @page_titles[idx] ? "#{@page_titles[idx]} (#{page})" : "Page #{page}"
  end

  def page_titles()
    10.times.map{|idx|
      page_title(idx + 1)
    }
  end
  
  def os_init
    if @os.windows?
      windows_init
    end
  end
  
  def windows_init
    # using power shell gem doesn't seem to work here
    `PowerShell -Command $host.ui.RawUI.WindowTitle = “WTH”`
  end

  def cpu_details
    if @os.windows?
      windows_cpu
    end    
  end
  
  # Example of windows CPU info dump...for future use
  def windows_cpu
# This is stupidly slow module ... wtf is it doing?
#    puts "Architecture: " + CPU.architecture.to_s
#    puts "CPU Speed (Frequency): " + CPU.freq.to_s
#    puts "Load Average: " + CPU.load_avg.to_s
#    puts "Model: " + CPU.model.to_s
#    puts "Type: " + CPU.cpu_type.to_s
#    puts "Num CPU: " + CPU.num_cpu.to_s
    CPU.processors{ |cpu|
       pp cpu
    }    
  end
  
end
Core.modules=@modules_registered

