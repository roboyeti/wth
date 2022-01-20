# Change Log

## VERSION 0.19f - 2022-1-20
- Added: Tor SOCKS proxy option for Tor installs.  Currently limited to per module config
- Change: Made WTH more responsive to changes in displays (data is now gathered in a master thread and screen updated regardless)
- Change: Changed how proxy works.  Mostly untested, but you now are expected to provide a proxy rather than WTH finding one for you
-- Solutions like Tor can be used with SOCKS, but Privoxy and other proxy over Tor would be used via this proxy config
- Change: Gemfile now has optional components to decrease gem size when necessary
-- Backed out these changes until we can document them
- Added: LibreHardwareMonitor/OpenHardwareMonitor GPU display (experimental, unsupported, undocumented for now)
- Added: CoinGecko plugin w/hook to translate coin# to $ worth (only dollar for now)
- Fixed: Some format bugs
- Fixed: Some modules not using optional config options
- Fixed: Performance blocking issues on some modules
- Fixed: Threading deadlock
- Change: Improved config documentation... I think.
- Change: Some general code cleanup
- Added: estimated revenue to xmrig / cpuminer, plus some other add/fixes/streamlines
- Added: other coin support for xmrig (and cpuminer) - for display and revenue calcs
- Change: working on module structs to be faster ... work in progress
- Change: Changed almost all modules to more flexible and streamlined design
- Change: Added column selection from config file for most modules (work in progress)
-- This will not have any effect on standalone or mining gpu data (per gpu that is)
- Change: Changed standalone look
- Added: Module for Nvidia-SMI-Rest (https://github.com/lampaa/nvidia-smi-rest)
- Change: Re-org on some code to reduce large files
- Added: NanoPool Module (nano pool reporting kind of sucks)
- Added: 2Miners Pool Module
- Change: Fixed self signed cert for running WTH in SSL
- Added: NBMiner module
- Changes: Lots of column adds/changes/smoothing out things
- Added: User defined "banner" module
- Fixed: Standalone fix
- Added Zapper.FI
- Removed: Save config option when config missing..
- Added: Instructions to use the example config.

## VERSION 0.18 - 2021-12-27
- Docs: More documentation / error corrections
- Docs: Markdown fixes
- Docs: BTC, ETC, ETH and XMR donation addresses added
- Docs: Added miner specific docs, README updates
- Fixed: More reliability of cpu miners on down
- Added: html_out config enabled
- Fixed: More fixes on pool downs
- Change: Decreased down re-check time
- Change: Increased REST call default timeout
- Fixed: Utilize page "cache" for faster UI page switches & refresh
- Change: Imposes min limit on frequency to 8 seconds, regardless of module settings
- Added: "f" force recheck on downed nodes for console.  May require a cycle to catch up in view
- Fixed: even longer delay for refresh than the lack of page cache use
- Fixed: GPU standalone mode to work, but not document-able feature yet.  Add "standlone: true" to modules.
- Change: Preliminary work on better header sizing
- Added: Ability to enable a shorter header for pages with "header_short: true"
- Added: GMiner gpu miner support module
- Added: Logging to file initial support.  More to be done.  "log_level: <level>" added to config
- Fixed: More resilient modules against errors in console output, catching the errors and logging them instead of crashing/terminating
- Added: Coin tracker "portfolio" module to track prices, holding value, avg cost of holdings, profit/loss (via coingecko)
- Added: Config directive "start_page: #" to display page other than default of 1st page
- Added: WTH Link Module!!!  Now a WTH instance can grab data and display it in source module format from another WTH module!
-- Why would I do that?  Well, for one, you could run a WTH instance inside one network grabbing data from multiple local miners and then pull that data from a publicly availble node while limiting firewall access to WTH node.
-- Worth noting, the goal is to provide a WTH push to WTH as well and this was step one, get the module instancing from WTH data etc.
- Added: Some fixes for data that wasn't getting to API output, such as revenue
- Added: "dump: true/false" flag for modules that will enable dumping to tmp directory the contents of the requested API calls for dev/troubleshooting
- Fixed: fixed gminer data for GPU share data
- Added: LolMiner support
- Added: NanoMiner support

## VERSION 0.17 - 2021-11-24
- Added: Handle errors/events better (more standardized)
- Added: API and basic web interfaces now have optional key protection
- Added: web config options: port, host, ssl, api, key
- Added: new config options enabled in web server as well
- Change: semi improved down host handling... needs more work...
- Added: self signed cert SSL added
    - Generates a new self cert and saves it.  Changing it makes Firefox angry.
    - Mostly untested.  Need to provide more SSL support/testing
- Removed: signum pool miner override of check_all, now consolidated
- Removed: extra pre-recheck round on down servers
- Added: Web logs
- Added: detach mode for non-Windows.  Untested.  Enabled when console output turned off
- Added: Enabled config options for turning off html output
- Added: Enabled config option for turning off console output (and input)
- Added: Option to disable / enable web service entirely
- Change:  Started working on new config module
- Added: Working missing config creates default config bits
- Added: Config documentation pass #1
- Fixed: Some miner / pool failures on down hosts
- Added: auto generated API key for WTH when config is missing and generated
- Added: Config for default checking frequency on modules (default is 12 in code)

## VERSION 0.16 - 2021-11-24
- Added: Simple Web API to request module json data.
    - localhost:8000/api?module=<your module config name | "list" to get those>
- Fixed: More fixes and consolidations to OpenStruct format versus hashes
- Changed: Standalone titles / tables to look slightly better
- Fixed: What to mine is now more accurate in general and new "fixup" framework added for odd ball miners (ex., Nice Hash!?!?!)
- Changed: Plugins are no longer auto init'd at class instantiation.  Calling app.init starts plugins and modules (in that order)

## VERSION 0.15 - 2021-11-21
- Improved: unmineable output
- Added: WhatToMine plugin
    - Added: Price plugin hooks to gpu modules
- Fixed threading issue on cache with concurrency semaphore
- Fixed threading issue on modules race condition
- Added: Pool coloring for workers up/down, stale, reject, and speed comaprisons to calc or avg
- Added: GPU coloring for rejects
- Added: wthlab for real time debugging
- Added: Some auto loading of libraries. Needs more work
- Changed: some extensions and directories
- Added: Startup option for specifying config file.
- Added: common.rb to allow different scripts to spin up with the needful.
- Changed: Console Init changed into a module.
- Elminiated most globals (still a couple lurking outside of colors/etc)

## VERSION 0.14 - 2021-11-17
- Verified: Trex 1.19.14 tested and works with no modifications
- Fixed: "e" command on web not working
- Added: plugin basic framework ... things that add functionality, not pages
- Added: auto loading of modules/plugins
- Added: naming of pages
- Added: web display named pages
- Fixed: header issues
- Fixed: Web interface => "l" and "w" commands not working
- Fixed: numerical key capture for web
- Fixed: threading resource exhaustion
- Fixed: web page timeout cancel
- Added: Unmineable base module created
