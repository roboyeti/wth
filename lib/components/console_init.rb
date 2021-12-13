# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# All things console render related ... mostly
#
# TODO:
#       Make optional
#       Clean up
#       Web output on other pages pre-rendered at app startup
#       See other TODOs below.
#
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-spinner'
require 'terminal-table'
require 'pastel'

# TODO: Eliminate
$pastel ||= Pastel.new

module ConsoleInit

  # Command help for console.
  def cmd_list
    [
        "1,2,3,4,5,6,7,8,9,0: Display Pages 1-10",
        "r: Refresh Screen",
        "f: Force recheck of down nodes",
        "c: Reload Config","s: Save Config","h: View Config",
        "l: View Events","w: View Web Log",
        "q: Quit",
    ]    
  end
  
  # Commands to show on web interface
  def web_cmd_list
    [
        "1,2,3,4,5,6,7,8,9,0: Display Pages 1-10",
    #    "r: Refresh Screen",
    #    "c: Reload Config","s: Save Config","h: View Config",
        "l: View Events","w: View Web Log",
    ]    
  end

  def cursor
    @cursor ||= TTY::Cursor
  end
  
  def pastel
    @pastel ||= Pastel.new
  end
  
  # Keyboard reader object
  # @returns [Object] Currently TTY::Reader object
  def reader
    @reader ||= TTY::Reader.new  
  end

  # One big rambling, ever growing key => proc if mess
  # TODO: abstract, clean up
  #
  def init_key_reader
    reader.on(:keypress) do |event|
      if event.value == "e"
        clear
        out = []
        
        out << console_header()
        cmd_list.each{|c| out << sprintf("%10s%-s",'',c) }
        out << "\n"
        puts out
        reader.read_line(" < Hit Return/Enter to continue >")
        clear
      end
    
      if ['1','2','3','4','5','6','7','8','9','0'].include? event.value
        $page = event.value.to_i >= 1 ? event.value.to_i : 10
        puts clear
        @loop_int = true
      end
      
      if event.value == "q"
        puts "Goodbye, so long, may your life be blessed!"
        exit
      end
      if event.value == "r"
        TTY::Screen.rows.times {|r|
          puts clear
        }
        @loop_int = true
      end  
      if event.value == "f"
        clear_all_down_nodes
        @loop_int = true
      end  
      if event.value == "c"
        clear
        puts "Reloading config..."
        load_config
      end  
      if event.value == "s"
        clear
        puts "Saving config..."
        save_config
        puts "Reloading config..."
        load_config
      end
      if event.value == "h"
        clear
        pp config
        reader.read_line(" < Hit Return/Enter to continue >")
        clear
        @loop_int = true
      end
      if event.value == "l"
        clear
        puts "Events:"
        puts get_log('events')
        reader.read_line(" < Hit Return/Enter to continue >")
        clear
        @loop_int = true
      end
      if event.value == "w"
        clear
        puts "Web Access Log:"
        puts get_log('web_log')
        reader.read_line(" < Hit Return/Enter to continue >")
        clear
        @loop_int = true
      end
      if event.value == "v"
        clear
        puts "System Information:\n"
        cpu_details
        reader.read_line(" < Hit Return/Enter to continue >")
        clear
        @loop_int = true
      end
  
    end
    return reader
  end
  
  # Loop interrupt flag
  # TODO: is lame
  #
  def loop_int
    @loop_int ||= false
  end
  
  # Set loop interrupt flag
  # TODO: is lame
  #
  def loop_int=(bool)
    @loop_int = bool
    @loop_int
  end
  
  # Dumb thing ...
  # TODO: replace. Was cut and pasted from original loop
  # and badly altered to easily work.
  #
  def keypress_pulse
    @loop_int=false
    reader.read_keypress(nonblock: true)    
    if @loop_int
      return true
    end
    return false
  end
  
  # Render console header for top of page.
  #
  # @param [String] page_title Optional page title
  # @param [Boolean] web Is for web render?  Possibly unused, optional
  # @return [Array] Array of lines to render
  #
  # Todo: web unused...I think
  #
  def console_header(page_title=" ",web=true)
    @header_short ? console_header_short(page_title,web) : console_header_long(page_title,web)
  end

  def console_header_long(page_title=" ",web=true)
    out = []
    border = pastel.blue.dim.detach
    center = pastel.magenta.dim.detach
    title = center.(" What The Hash? ~ BeRogue ~ https://github.com/roboyeti/wth ")
    time = Time.now.strftime("%Y/%m/%d %H:%M:%S")
  
    page = pastel.bright_green("#{page_title}") 
    stuff = border.("#{time} | #{version}v | e: View Commands")
    info = [page,stuff].join(' ')    
  
    # TODO: Simplify, gotten out of control... 
    mycols = 90
    title_length = no_ascii(title).length
    info_length = no_ascii(info).length
    
    longer = title_length > info_length ? title_length : info_length

#    longer = title.length > info.length ? title.length : info.length
    mycols = longer if longer > mycols
    
    top = border.( sprintf("╭%#{mycols-2}s╮",'─'*(mycols-2)) )
    pad_len = top.length - 2 - title.length
    len = (pad_len/2).round
    len2 = len + (pad_len % 2)
    out << top
    out << sprintf("%1s%#{len}s%s%#{len2}s%1s",border.('│'),'',title,'',border.('│'))
    out << border.( sprintf("╰%#{mycols-2}s╯",'─'*(mycols-2)) )
    out << sprintf("%#{top.length+8}s",info)
    out << ""
    out
  end       

  def console_header_short(page_title=" ",web=true)
    out = []
    border = pastel.blue.dim.detach
    center = pastel.magenta.dim.detach
    title = center.("What The Hash? https://github.com/roboyeti/wth")
    time = Time.now.strftime("%Y/%m/%d %H:%M:%S")
  
    page = pastel.bright_green("#{page_title}") 
    stuff = border.("#{time} | e:Commands")
    info = [page,stuff].join(' ')    
  
    # TODO: Simplify, gotten out of control... 
    mycols = 60
    title_length = no_ascii(title).length
    info_length = no_ascii(info).length
    
    longer = title_length > info_length ? title_length : info_length
    mycols = longer if longer > mycols
    
    top = border.( sprintf("╭%#{mycols-2}s╮",'─'*(mycols-2)) )
    pad_len = top.length - 2 - title.length
    len = (pad_len/2).round
    len2 = len + (pad_len % 2)
    out << top
    out << sprintf("%1s%#{len}s%s%#{len2}s%1s",border.('│'),'',title,'',border.('│'))
    out << border.( sprintf("╰%#{mycols-2}s╯",'─'*(mycols-2)) )
    out << sprintf(" %#{top.length}s",info)
    out << ""
    out
  end       

  def no_ascii(s)
    s.gsub /\e\[\d+m/, ""
  end
  
  # Clear screen
  #
  def clear
    cursor = TTY::Cursor
    printf cursor.clear_screen
    reposition
  end
  
  # Reset cursor to 0,0
  # TODO: Rename reset_cursor
  #
  def reposition
    printf cursor.move_to(0,0)
  end
  
  # Clear current text line
  #
  def clear_line
    printf cursor.clear_line
  end
  
  # Clear from current line down
  #
  def clear_screen_down
    printf cursor.clear_screen_down
  end
  
  # Hide the cursor.
  # Note:  Due to some oddness in some terminals, this may
  # have to be called in the main loop.
  #
  def cursor_hide
    printf cursor.hide
  end
end