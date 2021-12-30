# Author: BeRogue01
# License: See LICENSE file
# Date: 12/10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'rest-client'
require 'lightly'
require 'json'

class Modules::WthLink < Modules::Base
  using IndifferentHash  

  def initialize(p={})
    super
    @title = @config["title"] || "WthLink"
    @port = @config["port"] || 8080
    @remote_mod = @config["remote_module"]
    @key = @config["remote_key"]
    @target = {}
    @mod = {}
  end

  def my_module(host,mod)
	if !@target[host]
    @mod[host] ||= mod
	  m = @mod[host]
	  file = m.snake_case
	  load "./lib/modules/#{file}.rb"
	  @clss ||= m.constantize
	  @target[host] = @clss.new() #{ title: "#{@title}:#{@clss.name}" })
	end
    @target[host]
  end

  def check(ip,name)
    host,port,mod = ip.split(':')
    port = !port.to_s.empty? ? port : @port
  	mod ||= @remote_mod
    key_str = @key ? "&key=#{@key}" : ""
  	url = "http://#{host}:#{port}/api?module=#{mod}#{key_str}"
    res = simple_rest(url)
  	my_module(name,res["module"])
  	res
  end

  def console_out(data)
    hosts = data['addresses']
    rows = []
    hosts.each_pair{|k,v|
      rows << ['']
      rows << ["#{k.capitalize} : #{v["target"]} : #{@mod[k]}"]
      rows << [@target[k].console_out(v)]
    }
    table_out(["#{title} - #{data[:last_check_ago].ceil(2)} seconds ago"],rows)
  end
   
end