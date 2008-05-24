require File.dirname(__FILE__) + "/test_helper"

include Xample::Text

def repr(str, options = {})
  Example.new(str, options).finalize_example.representation
end

Expectations do 
  expect(e = Example.new("")) do 
    e.finalize_example
  end

  expect(Example.new("").
                 to.receive(:line_division).
                 returns(false)) do |e|
    e.finalize_example
  end
  
  expect(Example.new("foo").
                 to.receive(:analyze).
                 with("foo")) do |e|
    e.finalize_example
  end

  expect(Example.new("foo\nfoo").
                 to.receive(:analyze).
                 with("foo").times(2)) do |e|
    e.finalize_example
  end
  
  expect ["foo"] do 
    repr("foo")
  end

  expect ["foo"] do 
    repr("foo\n\n\n")
  end

  expect ["foo", "bar"] do 
    repr("foo bar")
  end

  expect ["foo"] do 
    repr("foo bar\nfoo")
  end

  expect ["bar"] do 
    repr("foo bar\nbar")
  end

  expect ["one", "two"] do 
    repr("one: two")
  end

  expect ["1000"] do 
    repr("1,000")
  end

  expect ["a", "1000"] do 
    repr("a 1,000")
  end

  expect ["a", "1000"] do 
    repr("a (1000)")
  end

  expect ["a", "b"] do 
    repr("a,b")
  end

  expect ["a", "b"] do 
    repr("a:b")
  end

  expect ["a", "b"] do 
    repr("a;b")
  end

  expect ["a", "b"] do 
    repr("a.b")
  end

  expect ["a","=","b"] do 
    repr("a=b")
  end

  expect ["a","==","b"] do 
    repr("a==b")
  end

  expect ["a","+","b"] do 
    repr("a+b")
  end

  expect ["a","+","b"] do 
    repr("a + b")
  end

  expect ["a","-","b"] do 
    repr("a-b")
  end

  expect ["a","/","b"] do 
    repr("a/b")
  end

  expect ["a","*","b"] do 
    repr("a*b")
  end

  expect ["a","%","b"] do 
    repr("a%b")
  end

  expect ["$", "1000"] do 
    repr("$1000")
  end

  expect ["foo", "bar"] do 
    repr('"foo" bar')
  end

  expect ["blah@blah.com", "bar"] do 
    repr('blah@blah.com bar', :dont_ignore => '.')
  end

  expect ["blah@blah", "com", "bar"] do 
    repr('blah@blah.com bar')
  end

  expect ["blah", "blah", "com", "bar"] do 
    repr('blah@blah.com bar', :ignore => '@')
  end

  expect ["foo", "bar"] do 
    repr('foo.bar')
  end

  expect ["blah", "@", "blah", "com", "bar"] do 
    repr('blah@blah.com bar', :separate_tokens => '@')
  end
end
