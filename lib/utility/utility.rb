  # Dynamic dir check and create ... jesus...
  # Returns the dir so you can set variables to a dir with this call and know
  # you have a working directory ... for the love of dog.
  #
  # @param dir [String] Directory to check and create if needed
  # @return [String] The directory name
  #
  def self.dyno_dir(d)
	return nil unless d
	if !Dir.exist?(d)
	  warn "Creating missing directory #{d}"
	  Pathname.new(d).mkpath
	end
	d
  end

#  def self.load_relative(file,safe=nil)
#	absolute = File.expand_path(file, __dir__)
#	load absolute, safe
#  end

  # Experimental required file reloader, mostly for IRB testing etc.
  # Not for general consumption!
  #
#  def self.reload
#	puts "Not implemented yet."
#	suppress_warnings {
#	  $SWARM_DIR_ORDER.each{|d|
#		$SWARM_FILES[d].each{|f|
#		  dir = File.join('lib',$SWARM_DIR,d)
#		  if f == '*'
#			glob = File.join('lib',$SWARM_DIR,d,'*.rb')
#			Dir[glob].each{|ff| load File.join(dir,File.basename(ff)) }
#		  else
#			load File.join(dir,"#{f}.rb")
#		  end
#		}
#	  }
#	  load './lib/swarm_p2p.rb'
#	}
#	puts "Reloaded lib files.  Might have worked... good luck!"
#	return true
#  end
end