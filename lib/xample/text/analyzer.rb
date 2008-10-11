module Xample
  module Text
    module Analyzer
      NUMBER = /[0-9](?:(?:[0-9,]*[0-9])|)/
      
      def ignore_tokens
        ((self.options[:ignore]-
          self.options[:dont_ignore])+
         self.options[:separate_tokens]).
          join('').
          gsub('-', '\-').
          gsub(']', '\]')
      end

      def separate_tokens
        Regexp.union(*self.options[:separate_tokens])
      end
      
      def token_pattern
        /(#{NUMBER})|(#{separate_tokens})|([^#{ignore_tokens}]+)/
      end

      def tokens_for(line)
        tokens = []
        line.scan(token_pattern) do |number, token, ignore|
          case
          when number
            tokens << number.gsub(',','')
          when token
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
      
      def typeof(val)
        return :int if (Integer(val) rescue nil)
        return :float if (Float(val) rescue nil)
        return :sym if Regexp.union(*self.options[:separate_tokens]) =~ val
        return :str
      end
    end
  end
end
   
