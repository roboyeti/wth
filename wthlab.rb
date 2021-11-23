# Author: BeRogue01
# License: Free yo, like air and water ... so far ...
# Date: 10/12/2021
#
# Love everybody,but never sell your sword.  ~ Paulo Coelho
#
require 'irbtools'
load './core/common.rb'

clear

$app = app = Core.new(
    :config_file => "wth_config.yml"                 
)

binding.irb