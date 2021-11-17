#require 'rubygems'
require 'em/pure_ruby'
require 'rack/websocket'
require 'sinatra/base'

class WebSocketApp < Rack::WebSocket::Application
  # ...
end

class SinatraApp < Sinatra::Base
  # ...
end

map '/ws' do
  run WebSocketApp.new
end

map '/' do
  run SinatraApp
end
