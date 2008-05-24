
module Xample
  module Text
    class Example
      DEFAULT_OPTIONS = { 
        :line_division => true,
        :ignore => [' ', ',', ':', ';', '(', ')', '"', '.'],
        :separate_tokens => ['=', '==', '$', '+', '*', '-', '/', '%'],
        :dont_ignore => []
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
      
      def initialize(str, options={})
        @options = merge_options(options)
        @str = str
        @representation = nil

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
      
      def action
        # TODO: implement
      end
      
      def finalize_example
        if self.line_division
          @str.each_line do |line|
            analyze(line.chomp) unless line.chomp == ''
          end
        end
        self
      end
      
      protected
      def analyze(line)
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
        
        @representation = tokens unless @representation
        add_new_optionals(tokens)
        
        if better(tokens)
          @representation = tokens
        end
      end
      
      def better(tokens)
        return false if tokens == @representation
        tokens.length < @representation.length
      end
      
      def add_new_optionals(tokens)
        @optionals += (tokens-@representation)
        @optionals.uniq!
      end
    end
  end
end
