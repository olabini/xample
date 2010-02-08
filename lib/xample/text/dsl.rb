require 'stringio'

module Xample
  module Text
    class DSL
      attr_reader :examples
      def initialize(&block)
        @examples = Examples.parse(&block)
      end
    
      def run(io_or_string)
        io = Utils::ensure_io(io_or_string)
        raise NoMatch unless @examples.match(io)
      end
    end      
  end
end
