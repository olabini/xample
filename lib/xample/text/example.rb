
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

      include Analyzer
      
      attr_reader :representation
      attr_reader :optionals
      attr_reader :options
      attr_reader :generated_actions
      attr_reader :real_literals
      
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
            analyze(line.strip) unless line.strip == ''
          end
        end
      end
      
      def parse_tree_for(blk)
        c = Class.new
        c.send :define_method, :synthetic_template_method, &blk
        tree = ParseTree.translate(c, :synthetic_template_method)
        tree[2][2]
      end
      
      def find_possible_literals_in_code(blk)
        tree = parse_tree_for(blk)
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
        match = Example.sliding_find(@representation, pl)
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
        ExampleMatcher.new(self).match(str)
      end
      
      #   * sliding_find([], [])                   #=> nil
      #   * sliding_find([], [1])                  #=> nil
      #   * sliding_find([1,2,3,4,5], [])          #=> nil
      #   * sliding_find([1,2,3,4,5], [0])         #=> nil
      #   * sliding_find([1,2,3,4,5], [1])         #=> [0, 0]
      #   * sliding_find([1,2,3,4,5], [1, 2])      #=> [0, 0]
      #   * sliding_find([1,2,3,4,5], [2])         #=> [1, 0]
      #   * sliding_find([1,2,3,4,5], [2, 3])      #=> [1, 0]
      #   * sliding_find([1,2,3,4,5], [2, 6])      #=> nil
      #   * sliding_find([1,2,3,4,5], [-1, 0, 1])  #=> [0, 2]
      #   * sliding_find([2,3,4,5], [-1, 0, 1, 3]) #=> [1, 3]
      def self.sliding_find(first, second)
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
      
      def replace_simple_literal(tree)
        lit = @real_literals.find { |lit_value, lit_num| lit_value == tree[1].to_s}
        if lit
          case tree[1]
          when Symbol
            [:call, [:dvar, :"literal_value_#{lit[1]}"], :to_sym]
          else
            ([:dvar, :"literal_value_#{lit[1]}"])
          end
        else
          tree.map { |v| replace_with_literals(v) }
        end
      end
      
      def find_literal_template(name)
        @real_literals.find do |lit_value, _, _| 
          lit_value.kind_of?(Array) && 
            lit_value.join("_").to_sym == name
        end
      end
      
      def replace_call_literal(tree)
        lit = find_literal_template(tree[2])
        if lit
          rest = replace_with_literals(tree[3])
          name_and_method_name = [:array, [:dvar, :"literal_value_#{lit[1]}"]]
          name_and_method_name += rest[1..-1] if rest
          [:call, replace_with_literals(tree[1]), :send, name_and_method_name]
        else
          tree.map { |v| replace_with_literals(v) }
        end
      end
      
      def replace_with_literals(tree)
        case tree
        when Array
          case tree[0]
          when :lit, :str
            replace_simple_literal(tree)
          when :call
            replace_call_literal(tree)
          else
            tree.map { |v| replace_with_literals(v) }
          end
        else
          tree
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
