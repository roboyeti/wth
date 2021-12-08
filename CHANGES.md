# Change Log

## VERSION pre-0.18 - 2021-12-06
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

## VERSION 0.17 - 2021-11-24
- Added: Handle errors/events better (more standardized)
- AddedL API and basic web interfaces now have optional key protection
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
