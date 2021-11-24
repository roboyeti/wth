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
#require 'sinatra'
require 'webrick'
require 'webrick/https'
require "terminal"

include WEBrick

class WTHBasicServlet < HTTPServlet::AbstractServlet

  def do_GET(request, response)
    qr_type = request.query["module"] ? 'module' : 'cmd'
    data = case qr_type
      when 'module' then module_handler(request)
      when 'command' then command_handler(request)
      else {}
    end
    
    response.status = 200
    response.body = data.to_json
    response['Content-Type'] = 	'application/json'
  end

  # Respond with an HTTP POST just as we do for the HTTP GET.
  alias :do_POST :do_GET

  # Handle modules requests
  def module_handler(request)
    qr_mod = CGI.unescape(request.query["module"] || "")
    if !qr_mod || qr_mod.empty?
      { message: "module not specified" }
    elsif qr_mod == "list"
      $app.modules.keys
    elsif !$app.modules.has_key?(qr_mod)
      { message: "no module #{qr_mod}" }
    else
      OpenStruct.new($app.modules[qr_mod].data).deep_to_h 
    end
  rescue => e
      { message: "unknown server error #{e} : #{e.backtrace[0]}" }
  end
  
  # Handle command requests
  def command_handler(request)
    { message: "command requests not enabled yet" }
  end
end

class WebServerBasic
  using IndifferentHash  
  include ConsoleInit
  
  attr_reader :config, :io_read, :io_write, :web_thread , :port, :host, :version
  
  def initialize(p={})
  	@config = p
  	@version = @config["version"] || ''
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
                :Logger => WEBrick::Log.new("tmp/webservice.log",10),
                #:SSLEnable => true,
                #:SSLCertName => cert_name
              )
      server.mount('/api', WTHBasicServlet )

      # Trap signals so as to shutdown cleanly.
      ['TERM', 'INT'].each do |signal|
       trap(signal){ s.shutdown }
      end
      
      server.start  
    }
    return @web_thread
  rescue
    puts "#{e} #{e.backtrace[0]}"
    exit
  end
  
  def read_io_nonblock
    r = @io_read.readline_nonblock
  rescue => e
#    puts e
#    exit
  end

  def write_html_file(file,name,content)
    if content.is_a?(String)
      content = content.split("\n")
    end
    web_hdr_out = console_header(name)
    ff = File.open("./web/generated/#{file}.html", 'w')
    ff.write(Terminal.render((web_hdr_out + content).join("\n")))
    ff.close
  end
  
  def write_html(titles,pages)
      fill = 10 - pages.length
      idx = pages.length
      fill.times{|p|
        pages[p + idx] = ["Nothing to show for this page"]
      }
      pages.each_with_index {|e,i|
        idx = i + 1
        web_hdr_out = console_header(titles[i])
        
        ff = File.open("./web/generated/page_#{idx}.html", 'w')
        ff.write(Terminal.render((web_hdr_out + e).join("\n")))
        ff.close
      }
  end
end

#class IO
#  def readline_nonblock
#    buffer = ""
#    buffer << read_nonblock(1) while buffer[-1] != "\n"
#
#    buffer
#  rescue IO::WaitReadable => blocking
#    raise blocking if buffer.empty?
#
#    buffer
#  end
#end