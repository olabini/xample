module Xample
  module Text
    class ExampleMatcher
      include Analyzer
      
      attr_reader :example
      attr_reader :options

      def initialize(example)
        @example = example
        @options = example.options
      end
      
      def match(str)
        ret = false
        if example.line_division
          str.each_line do |line|
            ret |= simple_match(line.strip) unless line.strip == ''
          end
        end
        ret
      end
      
      protected
      def simple_match(str)
        tokens = tokens_for(str.chomp) - example.optionals
        values = match_values(tokens, example.representation)
        return false unless values
        invoke_actions_with_values values
        return true
      end

      def invoke_actions_with_values(values)
        example.generated_actions.each do |action|
          action.call(*values)
        end
      end
      
      def match_atom(value, tvalue)
        (self.options[:keep_case] ? value == tvalue : tvalue.downcase == value.downcase) &&
          typeof(value) == typeof(tvalue)
      end

      def match_array_simple(value, tvalue, values)
        if typeof(tvalue) == value[1]
          values << to_type(tvalue, value[1])
          return true
        end
      end
      
      def first_divided_value?(value)
        value[1] && value[3] != 0
      end
      
      def match_array_divided(value, tvalue, values)
        xval = value[1] ? [] : values.last
        if first_divided_value?(value) 
          xval += example.real_literals[value[2]][0][0, value[3]]
        end

        if typeof(tvalue) == :str
          xval << tvalue
          values << xval if value[1]
          return true
        end
      end
      
      def match_array(value, tvalue, values)
        case value[0]
        when :literal
          match_array_simple(value, tvalue, values)
        when :divided_literal
          match_array_divided(value, tvalue, values)
        end
      end
      
      def match_value(value, tvalue, values)
        value.is_a?(Array) ?
          match_array(value, tvalue, values) :
          match_atom(value, tvalue)
      end
      
      def match_values(real, template)
        values = []

        return nil if template.length < real.length

        template.each_with_index do |val, ti|
          return nil unless match_value(val, real[ti], values)
        end

        transform_messages(values)
      end
      
      def transform_messages(values)
        values.map do |val|
          if Array === val
            unless self.options[:keep_case]
              val.join("_").downcase.to_sym
            else
              val.join("_").to_sym
            end
          else
            val
          end
        end
      end
    
      def to_type(val, type)
        case type
        when :int
          Integer(val)
        when :float
          Float(val)
        when :sym
          val.to_s
        when :str
          val.to_s
        end
      end
    end
  end
end
