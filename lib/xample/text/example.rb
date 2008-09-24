
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

      def merge_options(opts)
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
        @options = merge_options(options)
        @str = str
        @representation = nil
        @actions = []

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
      
      def finalize_example
        if self.line_division
          @str.each_line do |line|
            analyze(line.chomp) unless line.chomp == ''
          end
        end

        
        possible_literals = []
        @parsed_actions = []
        @actions.each do |blk|
          c = Class.new
          c.send :define_method, :synthetic_template_method, &blk
          tree = ParseTree.translate(c, :synthetic_template_method)
          tree = tree[2][2]
          @parsed_actions << tree
          literals = find_literals(tree)
          possible_literals += literals.inject([]) do |sum, val|
            sum << val
            if val.kind_of?(String)
              splitted = val.split('_')
              if splitted.length > 1
                sum << splitted
              end
            end
            sum
          end
          possible_literals.uniq!
        end
        @real_literals = []

        possible_literals.each do |pl|
          if @representation.include?(pl)
            index = @representation.index(pl)
            @representation[index] = [:literal, typeof(pl), @real_literals.length]
            @real_literals << [pl, index]
          elsif pl.kind_of?(Array)
            match = sliding_find(@representation, pl)
            if match
              (match[1]...(pl.length)).each do |lenix|
                @representation[match[0] + lenix - match[1]] = [:divided_literal, lenix == match[1], @real_literals.length, lenix]
              end
              @real_literals << [pl, *match]
            end
          end
        end

        @real_literals_sorted = @real_literals.sort_by do |v|
          v[1]
        end

        @generated_actions = []
        masgn = masng_for_literals(@real_literals_sorted)
        @parsed_actions.each do |pa|
          @generated_actions << eval(Ruby2Ruby.new.process([:iter, [:fcall, :proc], masgn, replace_with_literals(pa)]))
        end
        
        self
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
      
      def match_values(real, template)
        p [:match_values, real, template] if $DEBUG
        values = []
        template_index = -1
        template.each do |val|
          template_index += 1
          tval = real[template_index]
          if !val.kind_of?(Array)
            return nil if (@options[:keep_case] ? tval != val : tval.downcase != val.downcase)
            return nil if typeof(tval) != typeof(val)
          else 
            if val[0] == :literal
              return nil if typeof(tval) != val[1]
              values << to_type(tval, val[1])
            elsif val[0] == :divided_literal
              xval = val[1] ? [] : values.last
              if val[1] && val[3] != 0
                xval += @real_literals[val[2]][0][0, val[3]]
              end
              return nil if typeof(tval) != :str
              xval << tval
              values << xval if val[1]
            end
          end
        end
        if template_index < real.length-1
          return nil
        end
        return values.map do |val|
          if val.kind_of?(Array)
            if !@options[:keep_case]
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
              return [:dvar, :"literal_value_#{lit[1]}"]
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
          tokens = add_new_optionals(tokens)
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
      
      def add_new_optionals(tokens)
        @optionals += (tokens-@representation)
        @optionals += (@representation-tokens)
        @optionals.uniq!
        tokens - @optionals
      end
    end
  end
end
