#
# Hey, instead of making a basic, common data structure have the longest
# class name possible ... let's not... grrr
#
require 'symbolized'
class Sash < SymbolizedHash
  def initialize(p={})
	super
  end
end
