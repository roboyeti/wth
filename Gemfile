source 'https://rubygems.org'

gem 'openssl'

group :terminal, :console, optional: false do
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
end

# System gems
gem 'os'      # OS detection
gem 'sys-cpu' # Semi annoying system data
gem 'lightly' # File cache
#gem 'opencl-bindings'

# Deep state gems
gem 'rest-client'
gem 'concurrent-ruby', require: 'concurrent' # Used for thread safe vars
gem 'symbolized'  # For the love of ... Ruby hash needs help
gem 'zeitwerk'    # Code auto loader/reloader magic
gem 'semantic_logger'

# Misc
gem 'lucky_case'  # Adds various "case" conversions (snake, camel, etc)
gem 'sorted_set'  # Sort AoA?

# Server gems
gem 'daemons'

# Web server (wthd)
gem 'webrick'   # Current web server.  Should rpelace with thin or puma or unicorn
#gem 'sinatra'   # DSL for web routes
#gem 'puma'
#gem 'opal' # Someday ...
#gem 'rack'

# Modules / Plugins
gem 'coingecko_ruby'

# Notification clients
  # Pushover client for notifications
group :pushover, optional: true do gem 'rushover'; end

group :lab, optional: true do
  gem 'irbtools'    # Interactive ruby console
end

group :tor, :socksify, optional: true do
  gem 'socksify'
end

# TODO: Add other OS gems as needed
install_if -> { RUBY_PLATFORM =~ /mswin|mingw|cygwin/i } do
  gem 'winrm'
  gem 'ruby-pwsh' # Interface to powershell ... may not end up using it.  So far, hasn't done what I needed it for.
end
