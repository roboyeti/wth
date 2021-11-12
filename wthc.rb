# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# TODO: move more components to core.rb
# TODO: Config reload doesn't re-init the modules...
# TODO: Templates for console output
# TODO: Better HTML and Web commands
# TODO: solve the path issue to modules
# TODO: dynamic load modules
# TODO: Move web server out of main
# TODO: multi thread the checkers
# TODO: catch errors... and color on downs...
# TODO: Universal color templates
load './core/core.rb'
load './core/console_init.rb'

clear

$app = app = Core.new(
    :config_file => "wth_config.yml"                 
)

if app.newer_config_version?
  puts "="*79
  puts "Press 's' after interface loads to save with newer version of config options."
  puts "="*79
  sleep(5)
end

#clear
console_header().each {|o| clear_line; puts o; }

run_mods = app.init_wth_modules(app.config['modules'])
app.webserver_start
init_key_reader

$CFG = app.load_config
mod_out = {}
numcols = TTY::Screen.cols
$page = 1

# Main Loop
# - add web logs to web channel
# - setup screen stuff
# - iterate thru the modules
puts "Loading data into modules..."
#reposition

while 1
  page_out = 10.times.map{|| []}
  if TTY::Screen.cols != numcols
    numcols = TTY::Screen.cols
    clear
  end
  
  begin
    
    app.load_templates

threads = []
    run_mods.each_pair {|k,v|
thread = Thread.new {    
    Thread.current["me"] = v
    a = v.console_out(v.check_all)
    c = a.is_a?(Array) ? a : a.split("\n")
    Thread.current["mypage"] = c
    #page = (v.page || 1) - 1
    #  page_out[page] ||= []
    #  c.each {|l| page_out[page] << l }
    #  v.events.each {|event| $app.add_log('events',event) }
    #  v.clear_events
}
thread.abort_on_exception = true
threads << thread
    }
#pp threads
threads.each {|t|
  t.join;
  page = (t["me"].page || 1) - 1
  page_out[page] ||= []
  t["mypage"].each {|l| page_out[page] << l }
}

    #run_mods.each_pair {|k,v|
    #  a = v.console_out(v.check_all)
    #  c = a.is_a?(Array) ? a : a.split("\n")
    #  page = (v.page || 1) - 1
    #  page_out[page] ||= []
    #  c.each {|l| page_out[page] << l }
    #  v.events.each {|event| $app.add_log('events',event) }
    #  v.clear_events
    #}

    reposition
    cursor_hide
    console_header().each {|o| clear_line; puts o; }
 
    out = page_out[$page - 1] || ['Nothing to show']
    out.each {|o|
      clear_line
      puts o
    }
    clear_screen_down

    app.webserver_pulse(page_out)
    
    # =~ 6 seconds
    24.times { break if keypress_pulse(0.25) }
    
  #rescue => e
  #  puts "Error: #{e}."
  #  puts e.backtrace[0..10]
  #  if error_retry < 10
  #    puts "Retry in #{8*0.25} seconds"
  #    8.times { break if keypress_loop(0.25) }
  #    error_retry++
  #  end
  #  clear
  end
end


