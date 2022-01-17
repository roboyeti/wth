# Re-work of 
# Extend stdlib Struct with a factory method Struct::with_defaults
# to allow StructClasses to be defined so omitted members of new structs
# are initialized to a default instead of nil
module StructWithDefaults
  # makes a new StructClass specified by spec hash.
  # keys are member names, values are defaults when not supplied to new
  #
  # examples:
  # MyStruct = Struct.with_defaults( a: 1, b: 2, c: 'xyz' )
  # MyStruct.new       #=> #<struct MyStruct a=1, b=2, c="xyz"
  # MyStruct.new(99)   #=> #<struct MyStruct a=99, b=2, c="xyz">
  # MyStruct[-10, 3.5] #=> #<struct MyStruct a=-10, b=3.5, c="xyz">
  def better(*spec,&block)
    spec = Marshal.load(Marshal.dump(spec))
    new_args = []
    new_args << spec.shift if spec.size > 1
    spec = spec.first
    raise ArgumentError, "expected Hash, got #{spec.class}" unless spec.is_a? Hash
    new_args.concat spec.keys

    new(*new_args, keyword_init: true) do
      class << self
        attr_reader :defaults

        def after_create(block)
          @after_create_procs ||= []
          @after_create_procs << block
        end

        def after_create_procs
          @after_create_procs ||= []
        end
      end

      class_eval &block if block_given? 

      def do_after_create
        self.class.after_create_procs.each{|a|
          instance_eval(&a)
        }
      end

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
          hash[key] = if value.is_a?(OpenStruct) || value.is_a?(Struct)
            value.marshal_dump_recursive
          elsif value.is_a?(Hash)
            OpenStruct.new(value).marshal_dump_recursive
          elsif value.is_a?(Array)
            if value[0].is_a?(OpenStruct) || value[0].is_a?(Struct)
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

      def marshal_load(serialized_user)
        serialized_user.each_pair{|k,v|
          self[k] = v
        }
      end

      def self.deep_to_h(o)
        o.each_pair.map do |key, value|
          [
            key,
            case value
              when Struct then value.deep_to_h
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

      def initialize(**args)
        super
        self.class.defaults.each_pair{|k,v|
            self[k] = Marshal.load(Marshal.dump(args[k] ? args[k] : v))
        }
        do_after_create
      end
    end.tap{|s|
      spec2 = Marshal.load(Marshal.dump(spec))
      spec.each_pair{|k,v|
        spec2[k] = v.call if v.is_a?(Proc)
      }
      s.instance_variable_set(:@defaults, spec2.freeze)
    }

  end

end

Struct.extend StructWithDefaults
