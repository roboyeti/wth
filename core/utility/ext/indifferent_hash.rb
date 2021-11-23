# @project Misc Ruby Utility
# @author B.Rogue (original from stackoverflow).
# @license So free, it is scared of it's own freedom.
#
# Since this doesn't monkey patch at a lower level, it
# is only relevant to hashes you create within scope of the "using".
#
# Not really an ideal solution for much, but is an auto opt in
# solution for the ridiculous problem Ruby still has with str and
# sym keys not being the same key.
#
# Use:
# class SomeClass
#   using IndifferentHash
# end
#
module IndifferentHash
  refine Hash do
    def [](key)
      dig(key.to_s) || dig(key.to_sym)
    end

    def []=(key, val)
      if key.respond_to?(:to_sym)
        dig(key.to_sym) ? store(key.to_sym, value) : store(key.to_s, val)
      else
        store(key.to_s, val)
      end
    end
  end
end
