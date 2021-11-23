# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
load "./core/modules/claymore.rb"
class Phoenix < Claymore
  using IndifferentHash  
  
  def initialize(p={})
    super
    @title = p[:title] || 'Phoenix'    
  end
  
end