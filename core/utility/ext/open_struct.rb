# @project Misc Ruby Utility
# @author B.Rogue
# @license So free, it is scared of it's own freedom.
#
# Fix issue when merging open struct with hash...??? Why is this
# missing in core ruby modules?
#
class OpenStruct   
  def to_hash
    self.to_h
  end
end
