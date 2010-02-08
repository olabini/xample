require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

include Xample::Text

describe Analyzer do
  before :each do 
    @obj = Object.new
    @obj.extend Analyzer
  end
  
  describe "ignore_tokens" do 
    it "should be based on options" do 
      @obj.should_receive(:options).any_number_of_times.
        and_return(:ignore => ['a', 'b', '.'],
                   :dont_ignore => ['b'],
                   :separate_tokens => ['+'])
      @obj.ignore_tokens.should == "a.+"
    end
  end

  describe "separate_tokens" do 
    it "should create regexp based on separate tokens" do 
      @obj.should_receive(:options).
        and_return(:separate_tokens => ['+', "foo", 'x'])
      @obj.separate_tokens.should == /\+|foo|x/
    end
  end

  describe "token_pattern" do 
    it "should include numbers, separate tokens and ignore tokens" do 
      @obj.should_receive(:options).any_number_of_times.
        and_return(:ignore => ['a', 'b', '.'],
                   :dont_ignore => ['b'],
                   :separate_tokens => ['+', 'f', 'x'])
      @obj.token_pattern.should == /((?-mix:[0-9](?:(?:[0-9,]*[0-9])|)))|((?-mix:\+|f|x))|([^a.+fx]+)/
    end
  end

  describe "tokens_for" do 
    it "should handle simple tokens" do 
      @obj.should_receive(:options).any_number_of_times.
        and_return(:ignore => [" "],
                   :dont_ignore => [],
                   :separate_tokens => [])
      @obj.tokens_for("a b c").should == ["a", "b", "c"]
    end
  end

  describe "typeof" do 
    it "should be able to recognize ints" do 
      @obj.typeof("1").should == :int
      @obj.typeof("01").should == :int
      @obj.typeof("1000000000000032352345345345").should == :int
    end
    
    it "should be able to recognize floats" do 
      @obj.typeof("0.0").should == :float
      @obj.typeof("1.0").should == :float
      @obj.typeof("3244234232352354363463456.0").should == :float
      @obj.typeof("1.0e4").should == :float
    end
    
    it "should be able to recognize symbols" do 
      @obj.should_receive(:options).and_return(:separate_tokens => %w(foo))
      @obj.typeof("foo").should == :sym
    end
    
    it "should return strings for the rest" do 
      @obj.should_receive(:options).and_return(:separate_tokens => [])
      @obj.typeof("gah").should == :str
    end
  end
end
