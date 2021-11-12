module DynamicHash
  refine Hash do
    def [](key)
      dig(key.to_s) || dig(key.to_sym)
    end

    def []=(key, value)
      if key.respond_to?(:to_sym)
        dig(key.to_sym) ? store(key.to_sym, value) : store(key.to_s, value)
      else
        store(key.to_s, value)
      end
    end
  end
end
