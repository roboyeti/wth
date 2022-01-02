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
require 'daemons'
Daemons.run("wth.rb @ARGV[1..]")

#Process.setproctitle("zzzzzz")
#if $options.daemonize && app.os.windows?
#  f = spawn('ruby', "wth.rb") #, :out=>'NUL:', :err=>'NUL:')
#  Process.detach(f)
#  Process.wait(f)
#  exit

