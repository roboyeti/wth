# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
load "./lib/modules/gpu_miners/claymore.rb"
class Modules::EthMan < Modules::Claymore
  using IndifferentHash  
  
  $stderr.puts "EthMan is entirely untested!!!  Possibly will do nothing."

  def initialize(p={})
    super
    @title = p[:title] || 'EthMan'    
  end
  
end