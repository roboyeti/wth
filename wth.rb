#! /usr/bin/ruby
#
# Author: BeRogue01
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'tty-screen'
load './lib/common.rb'

app = Core.new(
  :config_file => $options.config_file
)

if $options.daemonize && app.os.windows?
  f = spawn('ruby', "#{__FILE__}", "-c $options.config_file") #, :out=>'NUL:', :err=>'NUL:')
  # TODO: Process.detach(f)
  Process.wait(f)
  exit
elsif $options.daemonize
  require 'daemons'
  init()
  Daemons.daemonize
  exit
end

if app.newer_config_version?
  puts "="*79
  puts "Press 's' after interface loads to save with newer version of config options."
  puts "="*79
  sleep(5)
end

app.load_templates
app.start

puts "Loading data into modules..."

numcols = TTY::Screen.cols
last_run = Time.now - 100
threaded = true # TODO: Turn into config option or just get rid of non-threaded code
pages_out = 10.times.map{|i| ['Loading data.  Could take some time ...'] }

# Endless good times.
# - add web logs to web channel
# - setup screen stuff
# - iterate thru the modules
# - print results (new or cached) to console, if enabled
# - pulse web server so it can get some work done.
thread = nil
loop do
  if !thread && ( (Time.now - last_run > 8) || app.down_reset? )
    thread = Thread.new {
      # Trap signals so as to shutdown cleanly.
      ['TERM', 'INT'].each do |signal|
        trap(signal){ exit; }
      end
      app.down_reset_clear
      Thread.current["pages_out"] = threaded ? app.thread_wth_modules : app.run_wth_modules
      app.webserver_pulse(pages_out)
      app.pulse
      true
    }
    thread.abort_on_exception = true
    last_run = Time.now
  end

  if thread && !thread.status
    pages_out = thread["pages_out"]
    thread.exit
    thread = nil
  end
  
  app.output_page(pages_out[app.current_page - 1] || ['Nothing to show'])
  
  # Sleep with keyboard responsiveness or thread wake up
  24.times {
    break if app.keypress_pulse
    app.update_screen
    if thread
      v = thread.join(0.1)
      break if v
    else
      sleep(0.25)
    end
  }  
end

