# @project Misc Ruby Utility
# @author B.Rogue
# @license So free, it is scared of it's own freedom.
#
# Fix issue when merging open struct with hash...??? Why is this
# missing in core ruby modules?
#
class OpenStruct   
  def to_h
    self.marshal_dump_recursive
  end

  def to_hash
    self.to_h
  end

  def a_json
    self.marshal_dump_recursive.to_json
  end

  def marshal_dump_recursive
    self.each_pair.with_object({}) do |(key, value), hash|
      hash[key] = if value.is_a?(OpenStruct)
        value.marshal_dump_recursive
      elsif value.is_a?(Array)
        if value[0].is_a?(OpenStruct)
          value.each.map{|v| v.to_h }
        else
          value
        end
      else
        value
      end
    end
  end

  def marshal_dump
    marshal_dump_recursive
  end

  def self.deep_to_h(o)
    o.each_pair.map do |key, value|
      [
        key,
        case value
          when OpenStruct then value.deep_to_h
          when Hash then OpenStruct.deep_to_h(value) 
          when Array then value.map {|el| el.class == OpenStruct ? el.deep_to_h : el}
          else value
        end
      ]
    end.to_h
  end
  
  def deep_to_h
    self.class.deep_to_h(self)
  end
  
  def as_json(options = nil)
    @table.as_json(options)
  end

end
