# Author: BeRogue01
# License: See LICENSE file
# Date: 11/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
class RunService < PluginBase

  def initialize(p={})
  	#super
    warn "RunService is not currently implemented"
  end
  
  def start
    Process.spawn(@cmd)
  end
  
  def checkup
	
  end
  
  def stop
	
  end

  def pulse
	# checkup
  end
  
end