require 'httpclient'
extheader = {
#  'GET' => '/summary',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
	#  'Host' => '127.0.0.1:4048',
	'Accept-Language' => 'en-US,en;q=0.5',
	'Accept-Encoding' => 'gzip, deflate',
#	'DNT': 1,
#	'Connection': 'keep-alive',
#	'Upgrade-Insecure-Requests': '1',
#	'Sec-Fetch-Dest': 'document',
#	'Sec-Fetch-Mode': 'navigate',
#	'Sec-Fetch-Site': 'none',
#	'Sec-Fetch-User': '?1',
	'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:94.0) Gecko/20100101 Firefox/94.0'
}
uri = 'http://127.0.0.1:4048/summary'
#clnt = HTTPClient.new
#puts clnt.get_content(uri, {}, extheader)

#h =  system("curl 'http://127.0.0.1:4048/summary' --output -")
#puts `curl --url "http://127.0.0.1:4048/summary" --output -`
require 'socket'

host = '127.0.0.1'
port = 4048

s = TCPSocket.open host, port
s.puts "GET /summary HTTP/1.1\n"
s.puts "Host: Firefox\n"
s.puts "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n"
s.puts "\n\n"

line = ""
begin
while line << s.getc
end
rescue
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