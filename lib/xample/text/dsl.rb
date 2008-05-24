require 'stringio'

module Xample
  module Text
    class DSL
      class Example
        attr_accessor :line_division
        
        def initialize(str)
          @str = str
          self.line_division = true
          @canonical = nil

          # This implementation ignore all words that are counted as
          # optional, not caring about position. This is definitely
          # wrong but simplifies the implementation right now

          # better representation is probably to have canonical be
          # something like ["foo", "bar", [:ignored, "abc", "bar"]]
          
          @optionals = []
        end
        
        def action
          # TODO: implement
        end
        
        def finalize_example
          if self.line_division
            @str.each_line do |line|
              analyze(line)
            end
          end
        end
        
        protected
        def analyze(line)
          tokens = line.split
          @canonical = tokens unless @canonical
          add_new_optionals(tokens)
          
          if better(tokens)
            @canonical = tokens
          end
        end
        
        def better(tokens)
          return false if tokens == @canonical
          tokens.length < @canonical.length
        end
        
        def add_new_optionals(tokens)
          @optionals += (tokens-@canonical)
          @optionals.uniq!
        end
      end
      
      class Examples
        class << self
          def parse(&block)
            examples = Examples.new
            examples.instance_eval(&block)
            examples.examples.each do |x|
              x.finalize_example
            end
            p examples
            examples
          end
        end

        attr_reader :examples
        
        def initialize
          @examples = []
        end
        
        def xample(io_or_string)
          io = Utils::ensure_io(io_or_string)
          x = Example.new(io.read)
          self.examples << x
          x
        end
      end
      
      def initialize(&block)
        @examples = Examples.parse(&block)
      end
      
      def run(io_or_string)
        io = Utils::ensure_io(io_or_string)
        # TODO implement
      end
    end
  end
end
