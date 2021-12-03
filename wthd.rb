#! /usr/bin/ruby
#
# Author: BeRogue01
# Date: 12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Only support on machines with fork
#
# ruby ./wthd.rb cmd [-- --conf <filename>] (maybe works...?!?!?)
#
# Commands:
#   start
#   stop
#   restart
#   status
#
require 'daemons'

# Default options
#$options = OpenStruct.new({ config_file: 'wth_config.yml'})
#
## Option parser
#OptionParser.new do |opts|
#  opts.banner = "Usage: wthc.rb [options]"
#
#  opts.on("-c", "--conf CONFIG_FILE","Specify config file.  Default is 'wth_config.yml'.") do |config_file|
#    $options.config_file = config_file
#  end
#  opts.on_tail("-h", "--help", "Show this message") do
#    puts opts
#    exit
#  end
#end.parse!
#

Daemons.run('wthc.rb')
