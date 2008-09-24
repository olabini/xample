
module Xample
  module Text
    class Examples
      include Enumerable
      class << self
        def parse(&block)
          examples = Examples.new
          examples.instance_eval(&block)
          examples.examples.each do |x|
            x.finalize_example
          end
#          p examples
          examples
        end
      end

      attr_reader :examples
      attr_reader :options
      
      def initialize
        @examples = []
        @options = {}
      end
      
      def each(&block)
        examples.each(&block)
      end
      
      def option
        @options
      end
      
      def xample(io_or_string)
        io = Utils::ensure_io(io_or_string)
        x = Example.new(io.read)
        self.examples << x
        x
      end
      
      def match(io)
        str = io.read
        result = false
        self.examples.each do |x|
          result |= x.match(str)
          return true if result
        end
        result
      end
    end
  end
end
