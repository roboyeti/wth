## ![WTH](/web/favicon/favicon-32x32.png) - What the Hash?
![WTH Web Interface](/screenshots/wth_web001.png)

## PLEASE NOTE: This is beta software and may not work as intended.  Please file issues if you find something broken!
- This is a new release of software.  It will have bugs.
- I mostly mine ETH, so mining other coins may or may not cause problems.  Report any you find, please.

## What is "What the Hash?"?
WTH is a "consolidator", that gathers data from different APIs, such as those on miners and pools, to  bring it
all together into one interface (console, web, and/or API).

See: [More Feature Screenshots of Modules](/docs/features.md)

WTH was designed with the goal of providing an expandable, quick
health status / earnings viewer for cryptocurrency related interests, miners, etc.

It was originally developed to allow me to get a fast view on the health of all my GPU/CPU miners, regardless of
miner software or pool software.  Mostly, I was frustrated at looking at half a dozen or more web pages just to check in on miners, pools, and portfolios.

It isn't meant to compete with fancy web UIs with charts and graphs (yet), but can easily run alongside those.  I have found that I rely less and less on the remote pool web interfaces to give me updates in addition to things like the portfolio not requiring me to share my holdings with external websites.

With very little interaction, you should be able to see the basics of your cryptocurrency
world.  Adding more mining pools, staking & liquidity pools, crypto portfolios, and more
is the plan.  

WTH also offers an API for other systems to use the collected data.  The primary
goal of this is so we can offer a more advanced Web UI in the future, but it also tries
to serve as a single API protocol for many different miners and pools out in the wild.

You can help us and add your own modules as well!  The coding required can be fairly 
simplistic, depending on the remote API, and help from us can get 
your module added quickly.  Don't program?  You can request the new module, but those who
donate get the most attention (see donation addresses below).  Requests can go here:
[Ideas](https://github.com/roboyeti/wth/discussions/categories/ideas)

WTH should be considered beta software.  I wrote it as a quick tool for myself, then it
proved so helpful, I started to grow it, and then I decided to release it.  Contributions 
to the code base are welcome, but only do so if you understand that this software is beta and
things will change.

Join the new [discord here](https://discord.gg/EZttsyQV)

By default, WTH offers the following modes:
* Console Interface
* Web Interface that is a mirror of the console interface
    - http://localhost:8080/
* JSON API of all modules
    - http://localhost:8080/api?module=list
    - http://localhost:8080/api?module=<your_module_entry_name|list>

## Installation - Windows
- Run the following to install automatically: #> .\install_win.ps1
- Copy wth_config_example.yml to wth_config.yml
- Edit config file (see Configuration)
- #> .\wth.rb (or double click in file window)
    - If .\wth.rb doesn't work, try 'ruby .\wth.rb'

Manual installation can be done as:
- Install Ruby: https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.2-1/rubyinstaller-3.0.2-1-x64.exe
- Optional: Install ConEmu: https://conemu.github.io/
- Open shell (power shell pref, even inside ConEmu)
- cd to installation directory
- #> bundle install --deployment
    
## Installation - Linux
- Coming soon! 
    - Install script for linux
    - Install for ARM
- Ubuntu Desktop 20.04/21.10 & Ubuntu Server 20.04-3/21.10
- Install Ruby dependencies
    -  sudo apt install curl g++ gcc autoconf automake bison libc6-dev libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev make pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev
- Make sure your system is up-to-date (we'll be doing this a lot)
    -  $ sudo apt-get update -y && sudo apt-get upgrade -y
- Install ruby 2.7+ for Ubuntu
    -  $ sudo apt install ruby-full
- Update your system    
    -  $ sudo apt-get update -y && sudo apt-get upgrade -y
- Confirm Ruby 2.7+: 
    -  $ ruby --version
- Download tar.gz from releases https://github.com/roboyeti/wth/releases/
    -  create a folder in /home called 'wth'
    -  copy release tar.gz to /home/wth
    -  cd /home/wth
    -  extract release tar.gz to /home/wth with your favorite app or
- Extract from Terminal:
    - $ tar -xf release.tar.gz (don't forget to replace release.tar.gz with actual filename)
- cd to /home/wth
- Install Ruby Bundler
    -  $ sudo apt install ruby-bundler 
    -  $ sudo gem install bundler:2.2.32
- $ bundle install --deployment
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
- Example config file is "wth_config_example.yml"
- You can run with different config file using arguments to wth: -c <FILE> or --config <FILE>
    - Example: ruby wth.rb -c wth_my_other_config.yml

## Configuration - Modules
- Modules are interfaces to software installed on your mining machines or remote APIs.  You may have to install software yourself on one or more machines to get the features of a module.
- Specific configuration options can be found in the example config.
- Brief documentation for how to enable APIs for a specific module target can be found in docs/modules/<target_name>.

List of supported modules and the config "api" entry for them:

GPU Miners
- Excavator (Nicehash Nvidia Miner) = "nice_hash"
- Claymore Miner = "claymore" (untested)
- Phoenix Miner = "phoenix"
- T-Rex Miner = "t_rex_unm"
- GMiner = "g_miner"
- LolMiner = "lol_miner"
- NanoMiner = "nano_miner"
- NBMiner = "nbminer"
    
CPU Miners
- XMRig = "xmrig"
- Cpuminer-gr = "raptoreum"
- Cpuminer-<algo> = "cpuminer" (Untested other than cpuminer-gr)

Harddrive Miners
- Signum Miner (via pool API) = "signum_pool_miner"

Pools
- 2Miners = "2miners_pool"
- Nano Pool = "nano_pool"
- Signum Pool API = "signum_pool_view"
- Flock Pool (RTM) = "flock_pool"
- Unmineable (Address API) = "unmineable" (best with local Tor installation for socks poxying)

Tokens
- Signum Tokens = "signum_tokens"
- ZapperFi = "zapper_fi" - Includes ETH tokens, Avalanche, and more. See http://zapper.fi

Portfolio
- Coingecko = "coin_gecko" - Build your own personal portfolio without sharing your data.  Pricing is possible on any coin CoinGecko supports.  See http://coingecko.com

Hardware
- LibreHardwareMonitor +WMI GPU/CPU monitoring on Win32 = "ohm_gpu_w32"  (Experimental)
-- Comaptibility with OpenHardwareMonitor possible, but  untested.  (Experimental)
- Nvidia SMI Remote (https://github.com/lampaa/nvidia-smi-rest) = "smi_rest"

Misc Modules
- WTH can pull data from another WTH instance = "wth_link"
- Banner = "banner" - Inserts a banner of text by position in config and page#

## Configuration - Plugins
- Specific configuration options can be found in the example config.

List of supported plugins
* what_to_mine : Enables what to mine revenue calculations on supporting modules
* coin_gecko : Enables value calculations for modules to convert to USD (more currencies supported soon)
    
## Configuration - Global
console_out: [true|false] = Enable console output.

web_server_start: [true|false] = Run web server or not

default_module_frequency: [integer] = Number of seconds between default module check.  Override per module with "every:" directive.  Some modules have minimums enforced to ensure you don't get yourself banned or overload remote APIs that are generously provided by others for free.

## Configuration - Web Server
The following web server config options are:

web_server:

  html_out: [true|false] = Enable the console => html conversion.  Turning this off will leave the API running, if that is enabled.  True default.
  
  port: [integer] = Port number to run basic and API on.  Default is 8080
  
  host: [network_addr] = For local machine access, set to 127.0.0.1 or localhost, 0.0.0.0 for all interfaces (default), or specific IP address for a specific interface.
  
  ssl: [true|false] = Enables SSL.  Your SSL cert and pkey pem files will be generated for you and stored in "data/ssl/*.pem".  You can replace those with your own if you desire.
  
  api: [true|false] = Enable the API interface for the web server.  Default false.
  
  key: [string] = User chosen string to act as you private web access string.  Append all URL requests with &api_key=<your_key> if you set this.

## Configuration - Misc Notes
- Tor SOCKS and Http Proxy is available, but currently is enabled per module with no global mechanism to set it yet and not all modules support it (those who use custom network code: claymore, phoenix, cpuminer, zapper.fi).

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

## Example Web View
![Example](/screenshots/wth_web001.png)
![Example](/screenshots/wth_web002.png)
## Example Console View
![Example](/screenshots/wth_console01.png)
![Example](/screenshots/wth_console02.png)
