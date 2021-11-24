# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'tty-screen'
load './core/common.rb'

threaded = true
numcols = TTY::Screen.cols
$page = last_page = 1

$app = app = Core.new(
  :config_file => $options.config_file
)
app.clear

if app.newer_config_version?
  puts "="*79
  puts "Press 's' after interface loads to save with newer version of config options."
  puts "="*79
  sleep(5)
end

#clear
#console_header().each {|o| clear_line; puts o; }

run_mods = app.init_wth_modules(app.config['modules'])
app.webserver_start
app.init_key_reader

$CFG = app.load_config

# Main Loop
# - add web logs to web channel
# - setup screen stuff
# - iterate thru the modules
puts "Loading data into modules..."
app.load_templates

last_run = Time.now - 10
while 1
  
  last_page = $page
  
  if TTY::Screen.cols != numcols
    numcols = TTY::Screen.cols
    app.clear
  end
    
  begin
#    if Time.now - last_run > 6  
      page_out = threaded ? app.thread_wth_modules : app.run_wth_modules

      app.reposition
      app.cursor_hide
      app.console_header(app.page_title($page - 1)).each {|o| app.clear_line; puts o; }
   
      out = page_out[$page - 1] || ['Nothing to show']

      out.each {|o|
        app.clear_line
        puts " #{o}"
      }
      app.clear_screen_down
  
      app.webserver_pulse(page_out)
#    end
  end    

  24.times { break if app.keypress_pulse(0.25) }  
end

