require 'socket'

host = '192.168.0.113'
port = 4048

s = TCPSocket.open host, port
s.puts "GET /summary HTTP/1.1\n"
s.puts "Host: Firefox\n"
s.puts "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n"
s.puts "\n\n"

line = ""
begin
while l= s.getc
  line << l if l
end
#rescue
end
puts line.chomp

s.close
exit
#require "http"
#require 'rubygems'
#require 'typhoeus'

#url = 'http://127.0.0.1:4048/summary'

#puts Typhoeus.get(url)
#GET /summary HTTP/1.1

#connection = Excon.new(url, :debug_request => true, :debug_response => true, :headers => { "Accept-Encoding" => "gzip" })
#response = connection.get
#puts response.body       # => "..."

#puts HTTP.get(url).to_s
#require 'net/http'
#Net::HTTP.get('127.0.0.1:4048', '/summary') do {|str|
#  puts str
#}