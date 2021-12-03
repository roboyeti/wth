![WTH - What the Hash](/web/favicon-32x32.png)

What the Hash was designed with the goal of providing a explandable quick
health status / earnings viewfor crypto currency related interests, miners, etc.

It isn't meant to compete with fancy web UIs with charts and graphs.  It was originally
developed to allow me to get a fast view on the health of all my GPU/CPU miners, especially
for things that wouldn't get alerts generated from on one stop shop mining pools.

With very little interaction, you should be able to see the basics of your crypto currency
world.  Adding more mining pools, staking & liquidity pools, crypto pportfolios, and more
is the plan.

What the hash also offers an API for other systems to use the collected data.  The primary
goal of this is so we can offer a more advanced Web UI in the future, but it also tries
to serve as a single API protocol for many different miners and pools out in the wild.

What the hash is in it's early phases.  I wrote it as a quick tool for myself, then it
proved so helpful, I started to grow it, and then I decided to release it, but started
a refactor that is ongoing.  Contributions to the ccode base are welcome, but this tool
should be considered Beta stage at best.  Things will change.

## Installation - Windows
- Install Ruby: https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.0.2-1/rubyinstaller-3.0.2-1-x64.exe
- Optional: Install ConEmu: URL_HERE
- Open shell (power shell pref, even inside ConEmu)
- cd to installation directory
- #> bundle install
- Edit config file (see Configuration)
- #> ruby .\wth.rb (or double click in file window)

## Installation - Linux
- Install ruby 2.7+ for your platform
- Edit config file (see Configuration)
- cd to installation directory
- #> bundle install
- #> ruby ./wth.rb

## Installation - OSx
- Same as linux, unknown mileage

## Other stuff
- wthlab.rb is an interactive shell with a WTH application spun up with your config.
    - wthd.rb is an untested daemonized wth for OSs that support fork.
    - Use: ruby ./wthd.rb [start|stop|status|restart]

- to detach from console

## Configuration
- The default config file is "wth_config.yml"
- A default config can be created by running the program and then quiting (q)
- Example config file is "wth_config_example.yml"
- You can run with different config files with -c <FILE> or --config <FILE>
    - Example: ruby wth.rb -c wth_my_other_config.yml

## Configuration - Modules

## Configuration - Plugins

## Configuration - Web Server

## Configuration - Global

## Donate!
Donations are very welcome and if you find this program helpful.  If you want a
miner, pool, or other crypto currency related site/tool integrated, donations also go a
long way to convince me to investigate if it is possible and spend the personal time
adding something I don't need myself.

- BTC: TBD
- ETH: TBD
- ETC: TBD
- SIGNA: S-CJFF-3JYH-GMBY-D2DRX
- RTM: RCMPMeSS2CYSbepTEbR5X3dNpwDQFZxnHM
- XLM: TBD
