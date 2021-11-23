# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Core class for WTH.
#
require 'rest-client'
require 'yaml'
require 'json'
require 'socket'
require 'os'
require 'sys/cpu'
require 'lucky_case/string'
require 'bigdecimal'
require 'pastel'

#load './core/common.rb'
load './core/web_server_basic.rb'
#load './core/console_init.rb'

[ 'base', 'gpu_base', 'pool_base'].each{|mod|
  load "./core/modules/#{mod}.rb"
}
[ 'plugin_base'].each{|mod|
  load "./core/plugins/#{mod}.rb"
}


# Config related methods
class Core
  using IndifferentHash  
  include ConsoleInit
  include Sys

  attr :verbose
  attr_reader :config_file, :cfg, :modules, :plugins

  VERSION = "0.15"
  CONFIG_VERSION = 20211103

  DEFAULT_CONFIG = {
    "version" => CONFIG_VERSION,
    "settings" => {
      "html_out" => true,
      "console_out" => true,
    },    
    "modules" => {
    }
  }

  TEMPLATE_CONFIG = DEFAULT_CONFIG.merge({
    "modules" => {
      "unique_name_here": {
        "port": 41413,
        "api": "module_name",
        "extra": "Short Note",
        "coin": "ETH",
        "nodes": {
          "smelter": "192.168.0.101",
          "forge": "192.168.0.102:41414"
        },
      }
    }
  })   

  # Map from config entry to module class
  #
  MODULES = {
    'excavator' => "Excavator",
    'nice_hash' => "Excavator",
    'phoenix' => "Phoenix",
    'signum_pool_miner' => "SignumPoolMiner",
    'signum_pool_view' => "SignumPoolView",
    't_rex' => "TRex",
    'unmineable' => "Unmineable",
    'xmrig' => "Xmrig",
    'raptoreum' => "Cpuminer",
    'cpuminer' => "Cpuminer",
    'flock_pool' => "FlockPool",    
  }.freeze

  # Map from config entry to plugin class
  PLUGINS = {
    'conemu' => 'ConEmu',
    'con_emu' => 'ConEmu',
    'what_to_mine' => 'WhatToMine',
    
  }.freeze
  
  # TODO: Document
  def initialize(p={})
    @config_file = p["config"] || p["config_file"] || "wth_config.yml"
    @config_type = "yml"
    @verbose = p["verbose"] || false
    @page_titles = []
    if config["pages"]
      config["pages"].each_pair{|pn,pt|
        @page_titles[pn.to_i - 1] = pt
      }
    end
    @log = {}
    @modules = {}
    @os = OS
    @plugins = {}
    init_plugins(config["plugins"])
    os_init
  end

  # Config and core version stuff
  #
  def version ; VERSION ; end  
  def module_config_version ; CONFIG_VERSION ; end
  def current_config_version ; config["version"] ; end
  def config_version ; config["version"] ; end

  # There is a newer version of the config format
  # TODO: Maybe not going to work out.
  #
  def newer_config_version?
    current_config_version < module_config_version  
  end

  # A bare bones template in case you have nothing.
  #
  def template_config ; TEMPLATE_CONFIG ; end

  # Returns config hash, loading default one if needed.
  #
  # @returns Hash
  #
  def config
    if !@cfg
      load_config(@config_file)
    end
    @cfg
  end

  # Load basic "template" files
  # Not really full templates yet...
  # Should be watched for changes and re-loaded
  def load_templates
    load 'templates/pool_summary.rb'
    load 'templates/gpu_worker.rb'
    load 'templates/table.rb'
  end
  
  # Load or create/save/load template config file.  Sets and return config hash.
  #
  # @param String file Optional file, default uses config_file
  # @returns Hash
  #
  def load_config(file=config_file)
    puts "Loading config file #{file}..."
    @cfg = load_yaml(file) if File.file?(file)
    if @cfg.empty?
      puts "No config file found. Saving template config to '#{file}'..."
      @cfg = template_config
      save_config(file)
    else
      puts "Configuration loaded..."
    end
    if newer_config_version?
      STDERR.puts "There is a newer version of the configuration format than what your config file is using."
    end
    @cfg = DEFAULT_CONFIG.merge(@cfg)
    @cfg
  rescue => e
    puts "Unknown error loading config file '#{file}': #{e}"
    {}
  end
  
  # Save a config file out.
  #
  # @param String file Optional file, default uses config_file
  # @param Hash hash Optional hash to save, default is config/cfg.
  # @returns Boolean
  #
  def save_config(file=config_file,hash=cfg)
    hash["version"] = CONFIG_VERSION if newer_config_version?
    save_yaml(file,hash)
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

  # Save config to YAML.
  #
  # @param String file Optional file, default uses config_file
  # @param Hash hash Optional hash to save, default is config/cfg.
  # @returns Boolean
  #
  def save_yaml(file=config_file,hash=cfg)
    File.write(file, cfg.to_yaml) 
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

  # Dynamic load and init plugins
  #
  # @param [Hash] cfg The config section for plugins
  #
  def init_plugins(cfg)
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
    load "./core/plugins/#{file}.rb"
    obj = PLUGINS[name].constantize
    puts "Init Plugin: #{name} => #{obj.name}"
    @plugins[name] = obj.new(cfg)    
  end
  
  # Check module has nodes and exists
  #
  def check_wth_module?(name,cfg)
    api = cfg['api']
    !cfg["nodes"].empty? && MODULES[api]
  end
  
  # Dynamic load and init a module
  #
  # @param [Hash] cfg The config section for a module
  #
  def init_wth_module(name,cfg)
    api = cfg['api']
    file = MODULES[api].snake_case
    puts "Loading Module: #{name} => #{file}"
    load "./core/modules/#{file}.rb"
    obj = MODULES[api].constantize
    puts "Init Module: #{name} => #{obj.name}"
    obj = @modules[name] = obj.new(config: cfg)
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
  def init_wth_modules(h_mods)
    h_mods.each_pair {|m,p|
      init_wth_module(m,p) if check_wth_module?(m,p)  
    }
    modules
  end

  def init_cfg_modules()
    config["modules"].each_pair {|m,p|
      init_wth_module(m,p) if check_wth_module?(m,p)  
    }
    modules
  end

  # Run modules, unthreaded
  #
  # @return [Array] The pages to render form module pulse
  #
  def data_run_modules
    load_templates

		page_out = 10.times.map{|| []}
		@modules.each_pair {|k,v|
#      a =
      v.check_all
#      c = a.is_a?(Array) ? a : a.split("\n")
#      page = (v.page || 1) - 1
#      page_out[page] ||= []
#      c.each {|l| page_out[page] << l }
      v.events.each {|event| add_log('events',event) }
      v.clear_events
    }      
#		page_out
    true
  end
  
  # Run modules, unthreaded
  #
  # @return [Array] The pages to render form module pulse
  #
  def run_wth_modules
    load_templates

		page_out = 10.times.map{|| []}
		@modules.each_pair {|k,v|
      a = v.console_out(v.check_all)
      c = a.is_a?(Array) ? a : a.split("\n")
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
  #
  # @return [Array] The pages to render form module pulse
  #
	def thread_wth_modules
		threads = []
    @modules.each_pair {|k,v|
			thread = Thread.new {
          load_templates
					Thread.current["me"] = v
					a = v.console_out(v.check_all)
					c = a.is_a?(Array) ? a : a.split("\n")
					Thread.current["mypage"] = c
					Thread.current["events"] = v.events
					v.clear_events
			}
			thread.abort_on_exception = true
			threads << thread
    }
		page_out = 10.times.map{|| []}
		threads.each {|t|
			t.join;
			page = (t["me"].page || 1) - 1
			page_out[page] ||= []
			t["mypage"].each {|l| page_out[page] << l }    
			t["events"].each {|event| add_log('events',event) }
      t.exit
		}
		page_out
	end

  # Start web server
  # TODO: Enable port setting in config
  # TODO: Allow set IP to localhost only
  # TODO: Abstract in plugin
  #
  # @param [Integer] port The port to run service on.
  def webserver_start(port=8000)
    @webserver = WebServerBasic.new(
        :port => port,
        :version => version,
    )
    @webserver.start
    @webserver.write_html_file('events','Events',"Nothing to show")
    @webserver.write_html_file('web_logs','Web Logs',"Nothing to show")    
    wout = []
    web_cmd_list.each{|c| wout << sprintf("%10s%-s",'',c) }
    wout << "\n"
    @webserver.write_html_file('command_list','Commands',wout)
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
    # Non blocking read on webserver output to web access log
    io = @webserver.read_io_nonblock
    add_log('web_log',io) if io
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

  def page_title(idx)
    @page_titles[idx] || "Page #{idx + 1}"
  end

  def page_titles()
    10.times.map{|idx|
      @page_titles[idx] || "Page #{idx + 1}"
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
#puts "123"
#puts "234"
    CPU.processors{ |cpu|
       pp cpu
    }    
  end
  
end


