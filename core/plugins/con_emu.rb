# Author: BeRogue01
# License: See LICENSE file
# Date: 11/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# URL: https://conemu.github.io
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

end