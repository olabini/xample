require 'stringio'

module Xample
  module Text
    class DSL
      def initialize(&block)
        @examples = Examples.parse(&block)
      end
    
      def run(io_or_string)
        io = Utils::ensure_io(io_or_string)
        raise NoMatch
        # TODO implement
      end
    end      
  end
end
