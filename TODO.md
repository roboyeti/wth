#Todo List, kind of in order

## In Progess
- !!!: Adding smirest interface / module / startup
- !!!: Adding GPU CAPS XML parser
- !!!: Adding wonderland support module
- REJECTED/REWORKING: Added: initial proxy support for modules ... because unmineable API bottlenecking is ridiculous garbage
-- This proxy support leaves a lot to be desired and uses kind of crappy source for free proxy.
-- User beware, these proxies are rando servers, do not use for requests you don't want shared on the internet

## Easiest / highest prio
- Fix standalone ... broken in table_out
    - Auto font sizing of Single node to user defined size in config
    - Add single node support to cpu miners
- Finish converting errors to new methods
- Rainbow miner module
- Conemu start script (load config xml with background etc)
- Allow plugins to do something useful (part II)
- Document document document
- Add algo when and where possible
- More logging

## Medium / important
- finish universal color
    - replace color engine?
- Might consider suppression of title from config
- Logging - advanced
- web real certs
- Consider re-doing header on tables
- Pager added for logs
- Diagnose / submit hash rate bug to cpuminer-gr github
- Startup option for basic troubleshooting
- Add URL option for node lines and header
- Config reload doesn't re-init the modules...
- Finish send command isolation

## Medium / non-urgent
- Console init to module (ruby module)
- Add other commands to web interface
- Add suppression option to display Title on header
- Add optional title on single node
- Change header to table, I guess...
- templates

## Lowest or hardest (currently)
- Add URL for nodes on html page...? Would be nice tho...
