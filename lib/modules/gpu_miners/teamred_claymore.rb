# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
load "./lib/modules/gpu_miners/claymore.rb"
class Modules::TeamReadClaymore < Modules::Claymore
  using IndifferentHash  
  
  $stderr.puts "TeamRed Claymore is entirely untested!!!  Possibly will do nothing."

  def initialize(p={})
    super
    @title = p[:title] || 'TeamRedMiner'    
  end
  
end