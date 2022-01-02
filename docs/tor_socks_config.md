Tor Socks Server Setup

Download URL: https://www.torproject.org/download/tor/
Install Instructions: https://community.torproject.org/relay/setup/guard/

Tor can help WTH get around IP blocks on some remote services that have irrational ideas of API throttling.

Unmineable.com is one such site.  If you use unimneable and monitor more than a couple coins, they will block you, despite
the incredibly low frequency that WTH uses as defaults for checking.  They are unresponsive and now even their API docs
have gone missing, so frankly, they should be happy anyone is still trying to add value to their platform.

WTH can use Tor socks proxy directly, with no need to install a HTTP proxy layer on top of it.

Your config file (torrc) should look something like:

#Change the nickname "myNiceRelay" to a name that you like
Nickname myNiceRelay
#ORPort 9001
ExitRelay 0
SocksPort 9050
#Paths assume you extracted to C:\Users\torrelay\ - if you 
#extracted elsewhere or used a different username, adjust the 
#paths accordingly
DataDirectory C:\Users\torrelay\Data
Log notice file C:\Users\torrelay\tor\log\notices.log
GeoIPFile C:\Users\torrelay\Data\Tor\geoip
GeoIPv6File C:\Users\torrelay\Data\Tor\geoip6
#Put your email below - Note that it will be published on the metrics page
ContactInfo youremail@here.net

Alternate Option:
https://www.higithub.com/PeterDaveHello/repo/tor-socks-proxy
