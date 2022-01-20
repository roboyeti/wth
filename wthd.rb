#! /usr/bin/ruby
#
# Author: BeRogue01
# Date: 12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# Only support on machines with fork
#
# ruby ./wthd.rb cmd [-- --conf <filename>] (maybe works...?!?!?)
#
# Commands:
#   start
#   stop
#   restart
#   status
#
require 'os'
require 'daemons'

if OS.windows? #&& ARGV[0] == 'start'
  warn("This does not work right in windows.  Please just run .\\wth.rb")
  exit
end
pwd = Dir.pwd
Daemons.run_proc('wth.rb') do
  Dir.chdir(pwd)
  exec "ruby ./wth.rb"
end

# TODO: Windoze will have to be done with spawn + fork emulation...?
#Process.setproctitle("zzzzzz")
#if $options.daemonize && app.os.windows?
#  f = spawn('ruby', "wth.rb") #, :out=>'NUL:', :err=>'NUL:')
#  Process.detach(f)
#  Process.wait(f)
#  exit

