require File.dirname(__FILE__) + "/test_helper"

include Xample::Text

def repr(str, options = {})
  Example.new(str, options).finalize_example.representation
end

Expectations do 
  # These tests check the parsing of a single line
  expect ["foo", "bar"] do 
    repr('foo.bar')
  end

  expect ["blah", "@", "blah", "com", "bar"] do 
    repr('blah@blah.com bar', :separate_tokens => '@')
  end


  # These tests check the example unification
  
  expect ["foo"] do 
    repr("foo bar\nfoo")
  end

  expect ["bar"] do 
    repr("foo bar\nbar")
  end
end
