Change Log

* VERSION 0.15 - 2021-11-21
** Improved: unmineable output
** Added: WhatToMine plugin
*** Added: Price plugin hooks to gpu modules
** Fixed threading issue on cache with concurrency semaphore
** Fixed threading issue on modules race condition
** Added: Pool coloring for workers up/down, stale, reject, and speed comaprisons to calc or avg
** Added: GPU coloring for rejects
** Added: wthlab for real time debugging
** Added: Some auto loading of libraries. Needs more work
** Changed: some extensions and directories
** Added: Startup option for specifying config file.
** Added: common.rb to allow different scripts to spin up with the needful.
** Changed: Console Init changed into a module.
** Elminiated most globals (still a couple lurking outside of colors/etc)

* VERSION 0.14 - 2021-11-17
** Verified: Trex 1.19.14 tested and works with no modifications
** Fixed: "e" command on web not working
** Added: plugin basic framework ... things that add functionality, not pages
** Added: auto loading of modules/plugins
** Added: naming of pages
** Added: web display named pages
** Fixed: header issues
** Fixed: Web interface => "l" and "w" commands not working
** Fixed: numerical key capture for web
** Fixed: threading resource exhaustion
** Fixed: web page timeout cancel
** Added: Unmineable base module created
