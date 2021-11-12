# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# TODO: dynamic load different servers, init in core
# TODO: enable SSL
# TODO: Threads optional?
# TODO: logs
#
require 'sinatra'
require 'webrick'
require 'webrick/https'
require "terminal"

class WebServerBasic
  using DynamicHash
  attr_reader :config, :io_read, :io_write, :web_thread , :port, :host
  
  def initialize(p={})
	@config = p
    @port = @config["port"] || 8000
    @host = @config["host"] || 'localhost'
  end  
  
  # Spin up the server in a thread and connect
  # IO handlers to service IO.
  def start
    # IO Pipes to connect to thread IO
    @io_read, @io_write = IO.pipe
    port = @port
    
    # Basic web server thread   
    @web_thread = Thread.new{
    #  cert_name = [
    #    %w[CN localhost],
    #  ] 
      access_log = [
        [ @io_write, WEBrick::AccessLog::COMMON_LOG_FORMAT ],
      ]
    
      server = WEBrick::HTTPServer.new(
                :Port => port,
                :DocumentRoot => 'web',
                :AccessLog => access_log,
                #:Logger => WEBrick::Log.new("grr.log",1),
                #:SSLEnable => true,
                #:SSLCertName => cert_name
              )
      trap 'INT' do; server.shutdown; exit; end
      server.start  
    }
    return @web_thread
  end
  
  def read_io_nonblock
	io_read.readline_nonblock
  rescue
  end
  
  def write_html(pages)
      web_hdr_out = console_header(false)
      fill = 10 - pages.length
	  idx = pages.length
      fill.times{|p|
		pages[p + idx] = ["Nothing to show for this page"]
	  }
      pages.each_with_index {|e,i|
        ff = File.open("./web/page_#{i+1}.html", 'w')
        ff.write(Terminal.render((web_hdr_out + e).join("\n")))
#        ff.write(html_basic_page(TTY::Screen.cols,web_hdr_out + e))
        ff.close
      }
#      `copy ./web/page_#{$page}.html ./output.html`
  end
end
