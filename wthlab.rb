#! /usr/bin/ruby
#
# Author: BeRogue01
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'irbtools'
load './lib/common.rb'

clear

$app = app = Core.new(
    :config_file => "wth_config.yml"                 
)
puts "Use $app for access to WTH core app."
binding.irb