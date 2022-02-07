# Author: BeRogue01
# Date: 11/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'optparse'
require 'ostruct'
require "zeitwerk"
require 'semantic_logger'

Dir["./lib/utility/ext/*.rb"].each {|file| load file }

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.push_dir("lib")
loader.push_dir("lib/components")
loader.setup

# Set the global default log level
SemanticLogger.default_level = :info
# Log to a file, and use the colorized formatter
SemanticLogger.add_appender(file_name: 'wth.log')

# Create an instance of a logger
# Add the application/class name to every log message
#logger = SemanticLogger['MyClass']

# Default options
$options = OpenStruct.new({ config_file: 'wth_config.yml'})

# Option parser
OptionParser.new do |opts|
  opts.banner = "Usage: wthc.rb [options]"

  opts.on("-c", "--conf CONFIG_FILE","Specify config file.  Default is 'wth_config.yml'.") do |config_file|
    $options.config_file = config_file
  end
  opts.on("-d", "--daemonize","Daemonize on supported platforms") do
    $options.daemonize = 1
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!
