# Author: BeRogue01
# Date: 12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
module WthConfig

  def module_config_version ; @module_config_version ; end
  def current_config_version ; config["version"] || 0 ; end
  def config_version ; config["version"] || 0; end

  def set_module_config_version(v)
    @module_config_version = v
  end
  
  def dump_config(data,file="wth_config.yml")
    cfg = data.is_a?(Hash) ? data.to_yaml : data
    File.write(file, cfg)
  end
  
  def dump_example_config
  	dump_config(template_config,"wth_config_example.yml")
  end

  # A bare bones template in case you have nothing.
  #
  def template_config
%Q{---
##===========================================================================================
## Config file is in YAML format, which is far easier to use than JSON, but you
## have to keep the integrity of the indentation for nested attributes.
##===========================================================================================
##
## Version should not be change by hand.  It is a experimental feature to help keep
## your config file updated with new options as they are added.
version: #{module_config_version}
##===========================================================================================
## General settings
##===========================================================================================
## Console_out if true or false for console UI and data display
console_out: true
## Start the web server, true or false.  More web server settings under "web_server"
web_server_start: true
## Frequency to use for checking nodes when not specified in module
base_line_frequency: 8
pages:
    1: Overview
    2: Pools
    3: Standalone Testing
    4: I was here
    5: GPUs
    6: System
##===========================================================================================
## Web server settings
##===========================================================================================
web_server:
## Auto generate html output from console output.  Works even when console_out=false
  html_out: true
  port: 8080
## Host sets interface for web server.
## Examples: 127.0.0.1, localhost, 192.168.0.10, 0.0.0.0 (all interfaces).
## Default is 127.0.0.1, meaning only accessible on the local machine
  host: 0.0.0.0
  ssl: false
  api: false
## Auto generated uuid if you created config by running program.
## Uncomment to enable
#  key: #{SecureRandom.hex(15)}
##===========================================================================================
## Modules && Settings
##===========================================================================================
modules:
##
## Examples of modules are below.  The presence of a module config entry enables that
## plugin, which will be autoloaded on demand (specified in the "api:" option).
## The key is YOUR NAME for the module, allowing you to use the same API module for different
## checks & output panels, requiring only different keys.
##
## Common options, format, and descriptions / notes.
##
## your_unique_key_here:
##   api: <api_name> - REQUIRED! - This actually identifies the module to load for this entry.
##   extra: <your_mini_note> - Optional: Small note for the on display title
##   coin: <coin_symbol> - REQUIRED! - Used in display and price predictions.  Where
##         specified in the config, required, but consider it required for all miners
##   every: <integer> Optional: number of seconds between checks.  Some modules enforce
##          minimums, so be aware of that.
##   page: <integer> Optional: Integer, what page number to display on (1-10).  Default = 1
##   port: <integer> DEPENDS: Target service port number as integer, if required by module.  
##         In some cases, mod developer may have added common port as default for that miner.
##   nodes: Key/Value address pairs for module.  Could be name/ip or wallet_waddress/URL as
##          examples.
##     <name1>: <ip_address1>[:port#]
##     <name2>: <ip_address2>
##     <name3>: <ip_address3>
##   <module_settings1>: example of a module with unique setting. Described below per mod
##   <module_settings2>: example of a module with key/value unique setting.
##      <key1>: <value1>
##      <key2>: <value2>
##
## GPU module options:
##   gpu_rows: <Integer> - Optional, defaults to 5, specifies GPUS to show per row
##
## All modules settings will be provided in this example config for each module (for now).
##-------------------------------------------------------------------------------------------
#  t_rex_example1:
#    api: t_rex
#    port: 4067
#    coin: ETH
#    extra: ETH>BTT
#    gpu_row: 4
#    nodes:
#      <my_node>: <192.168.0.x>
#  phoenix:
#    api: phoenix
#    port: 33440
#    coin: ETH
#    extra: ETH
#    gpu_row: 5
#    nodes:
#      <my_node>: <192.168.0.x>:<port#>
#      <my_node2>: <192.168.0.x>
#  nice_hash:
#    api: excavator
#    port: 18000
#    coin: NICEHASH_ETH
#    extra: ETH
#    nodes:
#      <my_node>: <192.168.0.x>
#      <my_node2>: <192.168.0.x>
#  xmrig:
#    api: xmrig
#    port: 8989
#    coin: XMR
#    extra: XMR
#    every: 12
#    page: 1
#    nodes:
#      <my_node>: <192.168.0.x>
#  raptoreum:
#    api: cpuminer
#    port: 4048
#    coin: RTM
#    extra: RTM
#    every: 12
#    page: 1
#    nodes:
#      <my_node>: <192.168.0.x>
#  signum_pool_miner:
#    api: signum_pool_miner
#    api_node: https://europe1.signum.network
#    every: 180
#    page: 1
#    nodes:
#      <Signum address (not alias)>: <POOL URL>
#      <Signum address 2 (not alias)>: <POOL URL>
#    capacity:
#      <Signum address (not alias)>: <decimal amount of TiB>
#      <Signum address 2 (not alias)>: <decimal amount of TiB>
#  signum_pool_view:
#    api: signum_pool_view
#    every: 180
#    record_count: 15
#    show_block_winners: true
#    page: 2
#    nodes:
#      Signapool NotAllMine: https://signapool.notallmine.net
#    highlight_nodes:
#      <Signum address 1 (not alias)>
#      <Signum address 2 (not alias)>
#  unmineable:
#    api: unmineable
#    every: 300
#    page: 2
#    keys:
#      KEY: <your_unmineable_key_here>
#      SECRET: <your_unmineable_secret_key_here>
#    nodes:
#      <coin_name1>: <coin_address1>:<coin_symbol>
#      <coin_name1>: <coin_address1>:<coin_symbol>
#      <coin_name1>: <coin_address1>:<coin_symbol>
#  flock_pool:
#    api: flock_pool
#    every: 300
#    page: 2
#    nodes:
#      RTM: <RTM_ADDRESS>
#
##===========================================================================================
## Plugins && Settings
##===========================================================================================
plugins:
## ===== Whattomine.com =====
## Plugin for revenue/profit estimations on GPU/CPU using whattomine.com
#  what_to_mine:
#    lifespan: 300
#
## THE END
}
  end
end
