# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
#load './utils/nvidia_smi.rb'
# TODO: have modules auto load.
require 'rest-client'
require 'yaml'
require 'json'
require 'socket'
require 'os'

require 'pastel'
load './utils/ext/io.rb'
load './utils/ext/string.rb'
load './utils/ext/dynamic_hash.rb'
load './core/web_server_basic.rb'

[ 'base', 'gpu_base',
  'claymore','phoenix','excavator','t_rex',
  'xmrig',
  'signum_pool_miner','signum_pool_view',
  'unmineable'
].each{|mod|
  puts "Loading Module: #{mod}.rb"
  load "./core/modules/#{mod}.rb"
}

using DynamicHash

# Config related methods
class Core
  attr_reader :config_file, :cfg, :modules

  VERSION = "0.09"
  CONFIG_VERSION = 20211103

  DEFAULT_CONFIG = {
    "version" => CONFIG_VERSION,
    "settings" => {
      "html_out" => true,
      "console_out" => true,
      "gpu_view" => true,
#      "gpu_row" => 5,
    },    
    "modules" => {
    }
  }

  TEMPLATE_CONFIG = DEFAULT_CONFIG.merge({
    "modules" => {
      "module_example": {
        "port": 44444,
        "api": "module",
        "extra": "- ETH",
        "coin": "ETH",
        "nodes": {
          "smelter": "192.168.0.101",
          "forge": "192.168.0.102:41414"
        },
        "_not_enabled": {
          "kiln": "192.168.0.103:51515"
        }
      }
    }
  })   

  # Module map form config to Module
  MODULES = {
    'excavator' => Excavator,
    'phoenix' => Phoenix,
    'signum_pool_miner' => SignumPoolMiner,
    'signum_pool_view' => SignumPoolView,
    't_rex' => TRex,
    'unmineable' => Unmineable,
    'xmrig' => Xmrig,
  }

  def initialize(p={})
    @config_file = p["config"] || p["config_file"] || "wth_config.yml"
    @config_type = "json"
    @log = {}
    @modules = {}
    prep_windows if OS.windows?
  end

  def version ; VERSION ; end  
  def module_config_version ; CONFIG_VERSION ; end
  def current_config_version ; config["version"] ; end
  def config_version ; config["version"] ; end

  def newer_config_version?
    current_config_version < module_config_version  
  end

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
  def load_templates
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
  
  def add_log(type,val)
    @log[type] ||= []
    @log[type] << val
    @log[type].shift( @log[type].length - 30 ) if @log[type].length > 30
  end
  def get_log(type)
    @log[type] ||= []    
  end
  
  def check_wth_module?(name,cfg)
    api = cfg['api']
    !cfg["nodes"].empty? && MODULES[api]
  end
  
  def init_wth_module(name,cfg)
    api = cfg['api']
    @modules[name] = MODULES[api].new(config: cfg)
  end
  
  def init_wth_modules(h_mods)
    h_mods.each_pair {|m,p|
      puts "Init #{m} => #{p['api']}"
      init_wth_module(m,p) if check_wth_module?(m,p)  
    }
    @modules
  end
  
  def run_wth_module(name)
      
  end

  def webserver_start(port=8000)
    @webserver= WebServerBasic.new #(:port => port)
    @webserver.start
  end
  
  def webserver_pulse(pages)
    Thread.new{
      # Non blocking read on webserver output to web access log
      add_log('web',@webserver.read_io_nonblock)
      @webserver.write_html(pages)
    }
  end
  
  def write_file(file,out)
    ff = File.open(file, 'w')
    ff.write(Terminal.render(out.join("\n")))
    ff.close
  end
  
  def prep_windows
  #  `$host.ui.RawUI.WindowTitle = “WTH”`
  end
end


