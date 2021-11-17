# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# TODO: Move to module and work out how to not require this stuff
#
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-spinner'

require 'terminal-table'
require 'pastel'

$pastel = Pastel.new
$reader = TTY::Reader.new
$cursor = TTY::Cursor

$cmd_list = [
    "1,2,3,4,5,6,7,8,9,0: Display Pages 1-10",
    "r: Refresh Screen",
    "c: Reload Config","s: Save Config","h: View Config",
    "l: View Events","w: View Web Log",
    "q: Quit",
]

$web_cmd_list = [
    "1,2,3,4,5,6,7,8,9,0: Display Pages 1-10",
#    "r: Refresh Screen",
#    "c: Reload Config","s: Save Config","h: View Config",
    "l: View Events","w: View Web Log",
#    "q: Quit",
]

def reader
  @reader ||= TTY::Reader.new  
end

def init_key_reader
  reader.on(:keypress) do |event|
    if event.value == "e"
      clear
      out = []
      
      out << console_header()
      $cmd_list.each{|c| out << sprintf("%10s%-s",'',c) }
      out << "\n"
      puts out
      out << console_header()
      $web_cmd_list.each{|c| out << sprintf("%10s%-s",'',c) }
      out << "\n"
      $app.write_file("./web/command_list.html",out)
      reader.read_line(" < Hit Return/Enter to continue >")
      clear
    end
  
    if ['1','2','3','4','5','6','7','8','9','0'].include? event.value
      $page = event.value.to_i >= 1 ? event.value.to_i : 10
      @loop_int = true
    end
    
    if event.value == "q"
      puts "Goodbye, so long, may your life be blessed!"
      exit
    end
    if event.value == "r"
      TTY::Screen.rows.times {|r|
        puts $cursor.clear_line  
      }
    end  
    if event.value == "c"
      clear
      puts "Reloading config..."
      $app.load_config
    end  
    if event.value == "s"
      clear
      puts "Saving config..."
      $app.save_config
      puts "Reloading config..."
      $app.load_config
    end
    if event.value == "h"
      clear
      pp $app.config
      reader.read_line(" < Hit Return/Enter to continue >")
      clear
      @loop_int = true
    end
    if event.value == "l"
      clear
      puts "Events:"
      puts $app.get_log('events')
      reader.read_line(" < Hit Return/Enter to continue >")
      clear
      @loop_int = true
    end
    if event.value == "w"
      clear
      puts "Web Access Log:"
      puts $app.get_log('web_log')
      reader.read_line(" < Hit Return/Enter to continue >")
      clear
      @loop_int = true
    end
    if event.value == "v"
      clear
      puts "System Information:\n"
      $app.cpu_details
      reader.read_line(" < Hit Return/Enter to continue >")
      clear
      @loop_int = true
    end

  end
  return reader
end

def loop_int
  @loop_int ||= false
end

def loop_int=(bool)
  @loop_int = bool
  @loop_int
end

def keypress_pulse(sleepy=0.25)
  @loop_int=false
  reader.read_keypress(nonblock: true)    
  if @loop_int
    return true
  end
  sleep(0.25)
  return false
end

def console_header(page_title=" ",web=true)
  out = []
  border = $pastel.blue.dim.detach
  center = $pastel.magenta.dim.detach
  title = center.(" What The Hash? ~ BeRogue ~ https://github.com/roboyeti/wth ")
  time = Time.now.strftime("%Y/%m/%d %H:%M:%S")

#  info = if commands
  page = $pastel.bright_green("#{page_title}") 
  stuff = border.("#{time} | #{$app.version}v | e: View Commands")
  info = [page,stuff].join(' ')    
#  else
#    "#{page_title} - #{time} | #{$app.version}v | e: View Commands" #CFG_VER:#{$app.config_version}"    
#  end  
 
  mycols = 60
  longer = title.length > info.length ? title.length : info.length
  mycols = longer if longer > mycols
  
  top = border.( sprintf("╭%#{mycols-2}s╮",'─'*(mycols-2)) )
  pad_len = top.length - 2 - title.length
  # Look up Ruby modulous
  len = (pad_len/2).round
  len2 = len + (pad_len % 2)
#  len2 = (len*2) < pad_len ? len + 1 : len                                                                    
  out << top
  out << sprintf("%1s%#{len}s%s%#{len2}s%1s",border.('│'),'',title,'',border.('│'))
  out << border.( sprintf("╰%#{mycols-2}s╯",'─'*(mycols-2)) )
  out << sprintf("%#{top.length+8}s",info)
  out << ""
  out
end       

def clear
  cursor = TTY::Cursor
  printf cursor.clear_screen
  reposition
end

def reposition
  printf $cursor.move_to(0,0)
end

def clear_line
  printf $cursor.clear_line
end

def clear_screen_down
  printf $cursor.clear_screen_down
end

def cursor_hide
  printf $cursor.hide
end
