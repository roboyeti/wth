# Author: BeRogue01
# License: See LICENSE file
# Date: 11/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Base class for plugins
#
class PluginBase
  DOWNLOADS = [""]
  SHA5_SIGNATURES = [""]
  URL = ""
  VERSION = ""
  
  def initialize(p={})
  end

  def register
	 {}
  end
  
  def run
	
  end

  def pulse
	
  end

  # Quick and simple rest call with URL.
  # TODO: Get timeout working. Execute needs trouble shooting or gem replaced...
  def simple_rest(url,timeout=120)
#    s = if proxy
#          RestClient::Request.execute(:method => :get, :url => url, :proxy => proxy, :headers => {}, :timeout => timeout)
#        else
#          RestClient::Request.execute(:method => :get, :url => url, :headers => {}, :timeout => timeout)          
#        end
    s = RestClient.get url
    res = s && s.body ? JSON.parse(s.body) : {}
    begin
      s.closed
    rescue
    end
    res
  end  
end