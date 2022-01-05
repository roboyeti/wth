![WTH - What the Hash?](/web/favicon-32x32.png)
## WTH - What the Hash?

WTH was designed with the goal of providing a expandable quick
health status / earnings viewer for cryptocurrency related interests, miners, etc.

It isn't meant to compete with fancy web UIs with charts and graphs.  It was originally
developed to allow me to get a fast view on the health of all my GPU/CPU miners, especially
for things that wouldn't get alerts generated from on one stop shop mining pools.

With very little interaction, you should be able to see the basics of your cryptocurrency
world.  Adding more mining pools, staking & liquidity pools, crypto portfolios, and more
is the plan.

What the hash also offers an API for other systems to use the collected data.  The primary
goal of this is so we can offer a more advanced Web UI in the future, but it also tries
to serve as a single API protocol for many different miners and pools out in the wild.

What the hash is in it's early phases.  I wrote it as a quick tool for myself, then it
proved so helpful, I started to grow it, and then I decided to release it, but started
a refactor that is ongoing.  Contributions to the code base are welcome, but this tool
should be considered Beta stage at best.  Things will change.

By default, WTH offers the following modes:
* Console Interface
* Web Interface that is a mirror of the console interface
    - http://localhost:8080/
* JSON API of all modules
    - http://localhost:8080/api?module=list
    - http://localhost:8080/api?module=<your_module_entry_name|list>

## Installation - Windows
- Install Ruby: https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.2-1/rubyinstaller-3.0.2-1-x64.exe
- Optional: Install ConEmu: https://conemu.github.io/
- Open shell (power shell pref, even inside ConEmu)
- cd to installation directory
- #> bundle install --deployment
- Copy wth_config_example.yml to wth_config.yml
- Edit config file (see Configuration)
- #> .\wth.rb (or double click in file window)
    - If .\wth.rb doesn't work, try 'ruby .\wth.rb'
    
## Installation - Linux
- Install Ruby dependencies
    -  sudo apt install curl g++ gcc autoconf automake bison libc6-dev libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev make pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev
- Install ruby 2.7+ for your platform
- cd to directory where you extracted WTH 
- #> bundle install --deployment
- Copy wth_config_example.yml to wth_config.yml
- Edit config file (see Configuration)
- #> .\wth.rb
    - If .\wth.rb doesn't work, try 'ruby .\wth.rb'

## Installation - OSx
- Same as linux?, unknown mileage

## Use
- All modules can be spread across 10 "pages" for display and keys 1-0 bring you to the page.
- "e" key will show available commands in basic web interface and console
- http://localhost:8080/api?module=list provides a list of configured modules that can be queried.
    - http://localhost:8080/api?module=<module_name> will return JSON for that module entry
- With either web interface (basic or API), you can enable a private key to restrict access
    - Enable in config and set your key
    - Add &key=<your_key> to the URL for both interfaces to send it with request.
    
## Other stuff
- wthlab.rb is an interactive shell with a WTH application spun up with your config.
- wthd.rb is an untested daemonized wth for OSs that support fork.
    - Use: ruby ./wthd.rb [start|stop|status|restart]
- To detach from console, you can also set config option "console_out" to false
- When a URL is visible on the console, you may be able to CTRL + Mouse click it to open in browser.  Terminal and OS mileage may vary.

## Configuration
- The default config file is "wth_config.yml"
- A default config can be created by running the program and then quiting (q)
- Example config file is "wth_config_example.yml"
- You can run with different config file using arguments to wth: -c <FILE> or --config <FILE>
    - Example: ruby wth.rb -c wth_my_other_config.yml

## Configuration - Modules
- Specific configuration options can be found in the example config.
- Brief documentation for how to enable APIs for a specific module target can be found in docs/modules/<target_name>.

List of supported modules

GPU Miners
- Excavator (Nicehash Nvidia Miner) = "nice_hash"
- Claymore Miner = "phoenix" (untested)
- Phoenix Miner = "phoenix"
- T-Rex Miner = "t_rex_unm"
- GMiner = "g_miner"
- LolMiner = "lol_miner"
- NanoMiner = "nano_miner"

CPU Miners
- XMRig = "xmrig"
- Cpuminer-gr = "raptoreum"
- Cpuminer-<algo> = "cpuminer" (Untested other than cpuminer-gr)

Harddrive Miners
- Signum Miner (pool API) = "signum_pool_miner"

Pools
- Signum Pool API = "signum_pool_view"
- Flock Pool (RTM) = "flock_pool"
- Unmineable (Address API) = "unmineable"

Tokens
- Signum Tokens = "signum_tokens"

Portfolio
- Coingecko + personal coin portfolio

Hardware
- OpenHardwareMonitor +WMI GPU monitoring on Win32 and JSON API on all platforms OHM supports.  (Experimental)
- LibreHardwareMonitor +WMI GPU monitoring on Win32 and JSON API on all platforms OHM supports.  (Experimental)
-- These are not currently documented or formaly supported

WTH Link
- WTH can pull data from another WTH instance.
    
## Configuration - Plugins
- Specific configuration options can be found in the example config.

List of supported plugins
* what_to_mine : Enables what to mine revenue calculations on supporting modules

## Configuration - Global
console_out: [true|false] = Enable console output.

web_server_start: [true|false] = Run web server or not

default_module_frequency: [integer] = Number of seconds between default module check.  Override in module with "every:" directive

## Configuration - Web Server
The following web server config options are:

web_server:

  html_out: [true|false] = Enable the console => html conversion.  Turning this off will leave the API running, if that is enabled.  True default.
  
  port: [integer] = Port number to run basic and API on.  Default is 8080
  
  host: [network_addr] = For local machine access, set to 127.0.0.1 or localhost, 0.0.0.0 for all interfaces (default), or specific IP address for a specific interface.
  
  ssl: [true|false] = Enables SSL, which is not fully functional at this time.  False default. (not fully functional yet)
  
  api: [true|false] = Enable the API interface for the web server.  Default false.
  
  key: [string] = User chosen string to act as you private web access string.  If you run wth without a config, one will be generated with a unique string here.

## Configuration - Misc Notes
- Tor SOCKS and Http Proxy is available, but currently is enabled per module with no global mechanism to set it yet.

## Donate!
Donations are very welcome and if you find this program helpful.  If you want a
miner, pool, or other crypto currency related site/tool integrated, donations also go a
long way to convince me to investigate if it is possible and spend the personal time
adding something I don't need myself.

- BTC: bc1qwnuxek3zw6cht7gqm07smr7pam8qngl9l72jqk
- ETH: 0x0c3154E8bFB49Fc54e675f4D230737B76cAc8346
- ETC: 0x0b719bd9AD3786D340ea0D13465CB7EDe20c7DF5
- SIGNA: S-CJFF-3JYH-GMBY-D2DRX
- RTM: RCMPMeSS2CYSbepTEbR5X3dNpwDQFZxnHM
- XMR: 85AUKf2jByxRy884ebLagvToXmTW4hYmrhQUxvudKsvwWKpdKt1xMatargMD4DQTCCZgoxtiyrz6RTUXeciKGdz8Vqd9Ly8

## [Feature Screenshots](/docs/features.md)
## Example Console View
![Example](/screenshots/wth_con01.png)
![Example](/screenshots/wth_con02.png)
## Example Web View
![Example](/screenshots/wth_web01.png)
![Example](/screenshots/wth_web02.png)
