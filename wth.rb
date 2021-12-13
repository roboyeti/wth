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
app.clear

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
# TODO : Fix $page global, move page state to app
$page = last_page = app.start_page
last_run = Time.now - 100
threaded = true # Turn into config option
page_out = []

Process.daemon(true, true) if !app.console_out && !app.os.windows?

# Endless good times.
# - add web logs to web channel
# - setup screen stuff
# - iterate thru the modules
# - print results (new or cached) to console, if enabled
# - pulse web server so it can get some work done.
while 1
  
  last_page = $page
  
  if TTY::Screen.cols != numcols
    numcols = TTY::Screen.cols
    app.clear
  end
    
  if (Time.now - last_run > 8) || app.down_reset?
    app.down_reset_clear
    page_out = threaded ? app.thread_wth_modules : app.run_wth_modules
    app.webserver_pulse(page_out)
    app.pulse
    last_run = Time.now
  end
  
  out = page_out[$page - 1] || ['Nothing to show']

  if app.console_out
    app.reposition
    app.cursor_hide
    app.console_header(app.page_title($page - 1)).each {|o| app.clear_line; puts o; }
    out.each {|o|
      app.clear_line
      puts "#{o}"
    }
    #puts "Next check in #{(8 - (Time.now - last_run)).round(2)} seconds"
    app.clear_screen_down
  end
  
  # Sleep with keyboard responsiveness
  24.times {
    if app.console_out
      break if app.keypress_pulse
    end
    sleep(0.25)
  }  
end

