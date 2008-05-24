
module Xample
  module Text
    class Examples
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
  end
end
