require 'stringio'

module Xample
  module Text
    class DSL
      class Example
        def initialize(str)
          @str = str
        end
        
        def action
        end
      end
      
      class Examples
        class << self
          def parse(&block)
            examples = Examples.new
            examples.instance_eval(&block)
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
      end
    end
  end
end
