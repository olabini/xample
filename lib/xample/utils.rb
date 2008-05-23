
require 'stringio'

module Xample
  module Utils
    def self.ensure_io(obj)
      obj.kind_of?(String) ? 
        StringIO.new(obj) :
        obj
    end
  end
end
