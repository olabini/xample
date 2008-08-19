$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'expectations'
require 'spec'
require 'xample'

module BonusRegistration
end

class Swallower
  include Singleton
  def method_missing(name, *args, &block)
    $stderr.puts "Swallowed #{name}(#{args.inspect})" if $DEBUG
    Swallower.instance
  end
end

module Xample
  module Tests
    # Simple DSL that will basically do an action like this:
    # take the symbol for the currency
    # take the number for the amount
    # take the part ending, where ignored parts are "for", "for each", "on", "per"
    # then call BonusRegistration.create(num, currency) and then
    # construct a new method with the end of the words
    #   "per existing account" will call on_existing_account
    #
    # By default the examples are line based, doesn't care about spaces 
    # and other noise characters, except as for separation
    # It also doesn't care about case by default
    SimpleBonus = Xample::Text::DSL.new do 
      xample(<<DSL).
bonus $1000 each new account
bonus $1000 for new account
bonus $1000 on new account
bonus $1000 per new account
bonus $1000 new account
DSL
      action do 
        BonusRegistration.create(1000, "$").on_new_account
      end

      xample(<<DSL).
bonus 1000 USD each new account
bonus 1000 USD for new account
bonus 1000 USD on new account
bonus 1000 USD per new account
bonus 1000 USD new account
DSL
      action do 
        BonusRegistration.create(1000, "USD").on_new_account
      end
    end
  end
end
