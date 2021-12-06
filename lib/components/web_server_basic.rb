# Author: BeRogue01
# License: See LICENSE file
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# TODO: dynamic load different servers, init in core
# TODO: fix SSL
# TODO: Threads optional?
#
require 'webrick'
require 'webrick/https'
require "terminal"
require 'openssl'

include WEBrick

class WTHBasicServlet < HTTPServlet::AbstractServlet

  def do_GET(request, response)
    
    cli_key = CGI.unescape(request.query["key"] || "")

    if !@options[0] || cli_key == @options[0]
      qr_type = request.query["module"] ? 'module' : 'cmd'
      data = case qr_type
        when 'module' then module_handler(request)
        when 'command' then command_handler(request)
        else {}
      end
      
      response.status = 200
      response.body = data.to_json
      response['Content-Type'] = 	'application/json'
    else
      response.status = 401
      response.body = { message: 'Incorrect key provided.  See your config'}.to_json
      response['Content-Type'] = 	'application/json'
    end
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
  
  attr_reader :config, :io_read, :io_write, :web_thread , :port, :host, :ssl, :api, :version, :cert_file
  
  def initialize(p={})
  	@config = p
  	@version = @config["version"] || ''
    @port = @config["port"] || 8000
    @host = @config["host"] || 'localhost'
    @ssl  = @config["ssl"] || false
    @api  = @config["api"] || false
    @key  = @config["key"] || nil
    @html_out = @config["html_out"] || true
    @cert_file = @config["cert_file"] || 'data/wth.crt'
  end
  
  # Spin up the server in a thread and connect
  # IO handlers to service IO.
  def start
    # IO Pipes to connect to thread IO
    @io_read, @io_write = IO.pipe
    cert = if File.exist?(cert_file)
      File.read(cert_file)
    else
      crt = [['CN', WEBrick::Utils::getservername, OpenSSL::ASN1::PRINTABLESTRING ]]
      File.write(cert_file,crt)
      crt
    end
    access_log = [ [ @io_write, WEBrick::AccessLog::COMMON_LOG_FORMAT ] ]
    
    # Basic web server thread   
    @web_thread = Thread.new{
    
      server = WEBrick::HTTPServer.new(
                :Port => port,
                :BindAddres => @host,
                :DocumentRoot => 'web',
                :AccessLog => access_log,
                :Logger => WEBrick::Log.new("tmp/webservice.log",10),
                :SSLEnable => @ssl,
                :SSLCertName => cert
              )

      @fh = WEBrick::HTTPServlet::FileHandler.new(server,'web')

      # Mount the API handler  
      server.mount('/api', WTHBasicServlet, @key ) if api

      # Commandeer the root file handler to require key when enabled
      # and then either error or hand back to the FileHandler servlet
      server.mount_proc('/') {|request,response|
        cli_key = CGI.unescape(request.query["key"] || "")

        if request.path =~ /[\.css|\.jpg|\.png\.ico]/ || cli_key == @key
          @fh.do_GET(request,response)
        else
          response.status = 401
          response.body = 'Incorrect key provided.  See your config'
          response['Content-Type'] = 	'text/plain'
        end

      } if @key

      # Trap signals so as to shutdown cleanly.
      ['TERM', 'INT'].each do |signal|
        trap(signal){ server.shutdown; exit; }
      end
      
      server.start  
    }
    return @web_thread
  end
  
  def read_io_nonblock
    r = @io_read.readline_nonblock
  rescue
  end

  def write_html_file(file,name,content)
    return nil if !@html_out
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
        write_html_file("page_#{idx}",titles[i],e)
        
#        ff = File.open("./web/generated/page_#{idx}.html", 'w')
#        ff.write(Terminal.render((web_hdr_out + e).join("\n")))
#        ff.close
      }
  end
end
