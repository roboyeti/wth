# Author: BeRogue01
# License: See LICENSE file
# Date: 11/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Grabs a list of proxy severs:ports to proxy requests thru.
# Beware!  Using a proxy poses security risks of your personal
# information.  Requesting private, sensitive information should
# be done over SSL (https), at a minimum, and avoided entirely
# if you are uncertain of the risks.
#
# URL: https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all
# URL: https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=anonymous
# URL: https://docs.proxyscrape.com/
#
class ProxyRun < GetService
  DOWNLOADS = ["https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=anonymous"]
  SHA5_SIGNATURES = [""]
  URL = "https://docs.proxyscrape.com/"

  def initialize(p={})
  	super
  end
  
end
