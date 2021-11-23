source 'https://rubygems.org'

gem 'openssl'

# Notification clients
gem 'rushover'  # Pushover client for notifications

# Console gems (wthc)
gem 'tty-cursor'
gem 'tty-screen'
gem "tty-reader"
gem "tty-spinner"
gem 'pastel'
gem 'terminal-table'
#gem 'tty-pager' # Need to use
# Convert ansi to html 
gem 'terminal'

# System gems
gem 'os'      # OS detection
gem 'sys-cpu' # Semi annoying system data
gem 'lightly' # File cache

# Deep state gems
gem 'rest-client'
gem 'concurrent-ruby', require: 'concurrent' # Used for thread safe vars
gem 'symbolized'  # For the love of ... Ruby hash needs help
gem 'zeitwerk'    # Code auto loader/reloader magic

# Misc
gem 'lucky_case'  # Adds various "case" conversions (snake, camel, etc)
gem 'sorted_set'  # Sort AoA?
gem 'irbtools'    # Interactive ruby console

# Web server (wthd)
gem 'webrick'   # Current web server.  Should rpelace with thin or puma or unicorn
gem 'sinatra'   # DSL for web routes
#gem 'puma'
#gem 'opal' # Someday ...
#gem 'rack'

# This sucks,because it always ignores the use of Gemfile.lock.  Can't find a better
# solution.
# TODO: Add other OS gems as needed
if RUBY_PLATFORM =~ /mswin|mingw|cygwin/i
  gem 'ruby-pwsh' # Interface to powershell ... may not end up using it.  So far, hasn't done what I needed it for.
end
