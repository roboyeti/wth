require 'optparse'
require 'ostruct'
require "zeitwerk"

Dir["./core/utility/ext/*.rb"].each {|file| load file }

loader = Zeitwerk::Loader.new
loader.push_dir(__dir__)
loader.push_dir("core")
loader.setup

# Default options
$options = OpenStruct.new({ config_file: 'wth_config.yml'})

# Option parser
OptionParser.new do |opts|
  opts.banner = "Usage: wthc.rb [options]"

  opts.on("-c", "--conf CONFIG_FILE","Specify config file.  Default is 'wth_config.yml'.") do |config_file|
    $options.config_file = config_file
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!
