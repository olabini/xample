
module Xample
  module Text
    class Example
      DEFAULT_OPTIONS = { 
        :line_division => true,
        :ignore => [' ', ',', ':', ';', '(', ')', '"', '.'],
        :separate_tokens => ['=', '==', '$', '+', '*', '-', '/', '%'],
        :dont_ignore => [],
        :keep_case => false,
      }

      def self.merge_options(opts)
        obj = DEFAULT_OPTIONS.inject({}) do |hash, (key, value)|
          hash[key] = value.kind_of?(Array) ? value.dup : value
          hash
        end

        opts.inject(obj) do |hash, (key, value)|
          if hash[key] && hash[key].kind_of?(Array)
            if value.kind_of?(Array)
              hash[key] += value
            else
              hash[key] << value
            end
          else
            hash[key] = value
          end
          hash
        end
      end
      
      attr_reader :representation
      attr_reader :optionals
      
      def initialize(str, options={})
        @options = Example.merge_options(options)
        @str = str
        @representation = nil
        @actions = []
        @parsed_actions = []

        # This implementation ignore all words that are counted as
        # optional, not caring about position. This is definitely
        # wrong but simplifies the implementation right now

        # better representation is probably to have canonical be
        # something like ["foo", "bar", [:ignored, "abc", "bar"]]
        
        @optionals = []
      end

      def line_division
        @options[:line_division]
      end
      
      def action(&block)
        @actions << block
      end
      
      def analyze_lines!
        if self.line_division
          @str.each_line do |line|
            analyze(line.chomp) unless line.chomp == ''
          end
        end
      end
      
      def find_possible_literals_in_code(blk)
        c = Class.new
        c.send :define_method, :synthetic_template_method, &blk
        tree = ParseTree.translate(c, :synthetic_template_method)
        tree = tree[2][2]
        @parsed_actions << tree
        literals = find_literals(tree)
        literals.inject([]) do |sum, val|
          sum << val
          if val.kind_of?(String)
            splitted = val.split('_')
            if splitted.length > 1
              sum << splitted
            end
          end
          sum
        end
      end

      def raw_literal?(pl)
        @representation.include?(pl)
      end
      
      def divided_literal?(pl)
        pl.kind_of?(Array)
      end
      
      def set_literal_data(pl, real_literals)
        index = @representation.index(pl)
        @representation[index] = [:literal, typeof(pl), real_literals.length]
        real_literals << [pl, index]
      end

      def set_divided_literal_data(pl, real_literals)
        match = sliding_find(@representation, pl)
        if match
          (match[1]...(pl.length)).each do |lenix|
            @representation[match[0] + lenix - match[1]] = [:divided_literal, lenix == match[1], real_literals.length, lenix]
          end
          real_literals << [pl, *match]
        end
      end
      
      def identify_real_literals(possible_literals)
        real_literals = []

        possible_literals.each do |pl|
          case
          when raw_literal?(pl)
            set_literal_data(pl, real_literals)
          when divided_literal?(pl)
            set_divided_literal_data(pl, real_literals)
          end
        end

        real_literals
      end

      def analyze_literals!
        possible_literals = @actions.inject([]) do |sum, blk|
          sum + find_possible_literals_in_code(blk)
        end.uniq

        @real_literals = identify_real_literals(possible_literals)
        @real_literals_sorted = @real_literals.sort_by { |v| v[1] }
      end
      
      def finalize_example
        analyze_lines!
        analyze_literals!
        generate_actions!
        
        self
      end
      
      def generate_actions!
        masgn = masng_for_literals(@real_literals_sorted)
        @generated_actions = @parsed_actions.map do |pa|
          eval(Ruby2Ruby.new.process(
                                     [:iter, 
                                      [:fcall, :proc], 
                                      masgn, 
                                      replace_with_literals(pa)]))
        end
      end
      
      def match(str)
        ret = false
        if self.line_division
          str.each_line do |line|
            ret |= simple_match(line.chomp) unless line.chomp == ''
          end
        end
        ret
      end
      
      protected
      def simple_match(str)
        tokens = tokens_for(str.chomp) - @optionals
        values = match_values(tokens, @representation)
        return false unless values
        invoke_actions_with_values values
        return true
      end
      
      #   * sliding_find([], [])                   #=> nil
      #   * sliding_find([], [1])                  #=> nil
      #   * sliding_find([1,2,3,4,5], [])          #=> nil
      #   * sliding_find([1,2,3,4,5], [0])         #=> nil
      #   * sliding_find([1,2,3,4,5], [1])         #=> [0, 0]
      #   * sliding_find([1,2,3,4,5], [1, 2])      #=> [0, 0]
      #   * sliding_find([1,2,3,4,5], [2])         #=> [1, 0]
      #   * sliding_find([1,2,3,4,5], [2, 3])      #=> [1, 0]
      #   * sliding_find([1,2,3,4,5], [2, 4])      #=> nil
      #   * sliding_find([1,2,3,4,5], [-1, 0, 1])  #=> [0, 2]
      def sliding_find(first, second)
        return nil if second == [] || first == []
        len = first.length
        index = 0
        while index < len
          if first[index, second.length] == second
            return [index, 0]
          end
          index += 1
        end
        ret = sliding_find(first, second[1..-1])
        return [ret[0], ret[1]+1] if ret
        nil
      end

      def invoke_actions_with_values(values)
        @generated_actions.each do |action|
          action.call(*values)
        end
      end
      
      def match_value(value, tvalue, values)
        unless Array === value
          return nil if (@options[:keep_case] ? tvalue != value : tvalue.downcase != value.downcase)
          return nil if typeof(tvalue) != typeof(value)
        else 
          if value[0] == :literal
            return nil if typeof(tvalue) != value[1]
            values << to_type(tvalue, value[1])
          elsif value[0] == :divided_literal
            xval = value[1] ? [] : values.last
            if value[1] && value[3] != 0
              xval += @real_literals[value[2]][0][0, value[3]]
            end
            return nil if typeof(tvalue) != :str
            xval << tvalue
            values << xval if value[1]
          end
        end
        return true
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
            unless @options[:keep_case]
              val.join("_").downcase.to_sym
            else
              val.join("_").to_sym
            end
          else
            val
          end
        end
      end
      
      def masng_for_literals(literals)
        if literals.empty?
          nil
        else
          result = [:masgn, [:array]]
          literals.each do |val, num|
            result[1] << [:dasgn_curr, :"literal_value_#{num}"]
          end
          result
        end
      end
      
      def replace_with_literals(tree)
        case tree
        when Array
          case tree[0]
          when :lit, :str
            lit = @real_literals.find { |lit_value, lit_num| lit_value == tree[1].to_s}
            if lit
              case tree[1]
              when Symbol
                return [:call, [:dvar, :"literal_value_#{lit[1]}"], :to_sym]
              else
                return [:dvar, :"literal_value_#{lit[1]}"]
              end
            end
          when :call
            lit = @real_literals.find { |lit_value, _, _| lit_value.kind_of?(Array) && lit_value.join("_").to_sym == tree[2]}
            if lit
              rest = replace_with_literals(tree[3])
              name_and_method_name = [:array, [:dvar, :"literal_value_#{lit[1]}"]]
              name_and_method_name += rest[1..-1] if rest
              return [:call, replace_with_literals(tree[1]), :send, name_and_method_name]
            end            
          end
          return tree.map { |v| replace_with_literals(v) }
        else
          return tree
        end
      end
      
      def typeof(val)
        return :int if (Integer(val) rescue nil)
        return :float if (Float(val) rescue nil)
        return :sym if Regexp.union(*@options[:separate_tokens]) =~ val
        return :str
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
      
      def find_literals(tree)
        case tree
        when Array
          if [:lit, :str].include?(tree[0])
            return Array(tree[1].to_s)
          else
            res = []
            if [:call].include?(tree[0])
              res = Array(tree[2].to_s)
            end
            tree.each do |v|
              res += find_literals(v)
            end
            return res
          end
        else
          return []
        end
      end
      
      def tokens_for(line)
        number = /[0-9](?:(?:[0-9,]*[0-9])|)/
        separate_tokens = Regexp.union(*@options[:separate_tokens])
        ignores = ((@options[:ignore]-
                    @options[:dont_ignore])+
                   @options[:separate_tokens]).
          join('').
          gsub('-', '\-').
          gsub(']', '\]')

        tokens = []
        line.scan(/(#{number})|(#{separate_tokens})|([^#{ignores}]+)/) do |number, token, ignore|
          if number
            tokens << number.gsub(',','')
          elsif token
            if token == '=' && tokens.last == '='
              tokens[-1] = '=='
            else
              tokens << token
            end
          else
            tokens << ignore
          end
        end
        tokens
      end
      
      def analyze(line)
        tokens = tokens_for(line)
        if @representation
          tokens = add_optionals_as_intersection_of(tokens)
          if better(tokens)
            @representation = tokens
          end
        else
          @representation = tokens
        end
      end

      def better(tokens)
        return false if tokens == @representation
        tokens.length < @representation.length
      end
      
      def add_optionals_as_intersection_of(repr)
        @optionals += (repr-@representation)
        @optionals += (@representation-repr)
        @optionals.uniq!
        repr - @optionals
      end
    end
  end
end
