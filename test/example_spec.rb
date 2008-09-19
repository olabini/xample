require File.dirname(__FILE__) + "/test_helper"

include Xample::Text

def repr(str, options = {})
  Example.new(str, options).finalize_example.representation
end

describe Example do 
  describe "#finalize_example" do 
    it "should return itself" do 
      e = Example.new("")
      e.finalize_example.should == e
    end
    
    it "should call line_division" do 
      e = Example.new("")
      e.should_receive(:line_division).and_return(false)
      e.finalize_example
    end
    
    it "should call analyze with the string it was created with" do 
      e = Example.new("foo")
      e.should_receive(:analyze).with("foo")
      e.finalize_example
    end
    
    it "should call analyze once for every line" do 
      e = Example.new("foo\nbar")
      e.should_receive(:analyze).with("foo")
      e.should_receive(:analyze).with("bar")
      e.finalize_example
    end
  end
  
  describe "#representation" do 
    it "should parse a simple atom" do 
      repr("foo").should == ["foo"]
    end

    it "should parse a simple atom with lots of newlines after" do 
      repr("foo\n\n\n\n").should == ["foo"]
    end

    it "should parse two atoms separated by whitespace" do 
      repr("foo bar").should == ["foo", "bar"]
    end

    it "should parse two atoms separated by whitespace and colon" do 
      repr("foo: bar").should == ["foo", "bar"]
    end
    
    it "should ignore a comma inside if a number" do 
      repr("1,000").should == ["1000"]
    end

    it "should ignore a comma inside if a number when parsing several pieces" do 
      repr("a 1,000").should == ["a", "1000"]
    end

    it "should ignore parenthesis around something" do 
      repr("a (1000)").should == ["a", "1000"]
    end

    it "should separate on commas" do 
      repr("a,b").should == ["a", "b"]
    end

    it "should separate on colon" do 
      repr("a:b").should == ["a", "b"]
    end

    it "should separate on semicolon" do 
      repr("a;b").should == ["a", "b"]
    end

    it "should separate on dot" do 
      repr("a.b").should == ["a", "b"]
    end

    it "should separate and retain equals sign" do 
      repr("a=b").should == ["a", "=", "b"]
    end

    it "should separate and retain double equals sign" do 
      repr("a==b").should == ["a", "==", "b"]
    end

    it "should separate and retain plus sign" do 
      repr("a+b").should == ["a", "+", "b"]
    end

    it "should separate and retain plus sign with spaces" do 
      repr("a + b").should == ["a", "+", "b"]
    end

    it "should separate and retain dash sign" do 
      repr("a-b").should == ["a", "-", "b"]
    end

    it "should separate and retain slash sign" do 
      repr("a/b").should == ["a", "/", "b"]
    end

    it "should separate and retain multiplication sign" do 
      repr("a*b").should == ["a", "*", "b"]
    end

    it "should separate and retain percent sign" do 
      repr("a%b").should == ["a", "%", "b"]
    end

    it "should separate and retain dollar sign" do 
      repr("$1000").should == ["$", "1000"]
    end

    it "should ignore quotes" do 
      repr('"foo" bar').should == ["foo", "bar"]
    end

    it "should read mail address correctly with dot" do 
      repr('blah@blah.com bar', :dont_ignore => '.').should == ["blah@blah.com", "bar"]
    end

    it "should read mail address correctly" do 
      repr('blah@blah.com bar').should == ["blah@blah", "com", "bar"]
    end

    it "should handle ignore correctly" do 
      repr('blah@blah.com bar', :ignore => '@').should == ["blah", "blah", "com", "bar"]
    end
    it "should separate on dot with longer statement" do 
      repr("foo.bar").should == ["foo", "bar"]
    end
  end
end
