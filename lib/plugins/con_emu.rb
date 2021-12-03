# Author: BeRogue01
# License: See LICENSE file
# Date: 11/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# URL: https://conemu.github.io
#
# IN PROGRESS - NO ACTUAL CONNECTION TO APP
#
# Command to have conemu resize font.  Will change col #
# `ConEmuC -guimacro FontSetSize(0,18)`        
# Something like, but smarter...
#  if $page == 3 && last_page != 3
#    app.clear
#    `ConEmuC -guimacro FontSetSize(0,30)`
#  elsif $page != 3 && last_page == 3
#    app.clear
#    `ConEmuC -guimacro FontSetSize(0,18)`        
#  end
# Doesn't work...
#trap 'INT' do
#  puts "!!!!!!"
#  `ConEmuC -guimacro FontSetSize(0,18)`
#  exit
#end
# #conemu -FS -Here -NoMulti -Font "Consolas" -FontSize 18 -NoSingle -LoadCfgFile ".\conemu.xml" -run "ruby wthc.rb"
#
class ConEmu < PluginBase
  DOWNLOADS = ["https://www.fosshub.com/ConEmu.html?dwl=ConEmu_210912_English.paf.exe"]
  SHA5_SIGNATURES = ["ab447060cca171b54d06d918758a00544e108c42f91b4dd771cf8126da057772"]

  def initialize(p={})
    super
  end

  def standalone_font_do
  end
  
  def standalone_font_dont
  end

  def page_font_do
  end
  
  def page_font_dont
  end

end