# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
# This lib uses nvidia-smi to query gpu information, a tools provided by
# Nvidia and bundled only for use here without claim to ownership or rights.
#   SMI Copyright @ Nvidia
#   Url:
#

# nvidia-smi -L
# GPU 0: NVIDIA GeForce RTX 2060 SUPER (UUID: GPU-a8f0a75c-59a4-2e53-db56-c9c51b48b879)
# nvidia-smi -q -i 0

# Todo: OS and pathing

$WINDOWS_EXE = "nvidia-smi.exe"

class NvidiaSmi < PluginBase

  def initialize(p={})
    @exe = $WINDOWS_EXE
    @gpus = load_gpus
  end

  def load_gpus
    gpus = {
      devices: {},
      pci_map: {}
    }
    i = `#{@exe} -L`
    i.each {|l|
      l.chomp!
      id = l.split(':')[0].split(' ')[1]
      gpus[:devices][id] = {}
      o = `#{@exe} -q -i #{id}`
      #.gsub(/^\s*|\s*$/,'')
    }    
  end

end