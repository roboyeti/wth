# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
load "./lib/modules/claymore.rb"
class TeamReadClaymore < Claymore
  using IndifferentHash  
  
  def initialize(p={})
    super
    @title = p[:title] || 'TeamRedMiner'    
  end
  
end