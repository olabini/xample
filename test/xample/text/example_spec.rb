require File.dirname(__FILE__) + "/../../test_helper"

include Xample::Text

describe Example do
  describe "merge_options" do 
    it "should have correct default options" do 
      Example.merge_options({}).should ==
        {
          :line_division => true,
          :ignore => [' ', ',', ':', ';', '(', ')', '"', '.'],
          :separate_tokens => ['=', '==', '$', '+', '*', '-', '/', '%'],
          :dont_ignore => [],
          :keep_case => false,
        }
    end
      
    it "should not return something that can be modified and change the defaults" do 
      result = Example.merge_options({})
      result[:line_division] = false
      Example.merge_options({})[:line_division].should be_true

      result[:dont_ignore] = [1]
      Example.merge_options({})[:dont_ignore].should == []

      result[:ignore] << 'abc'
      Example.merge_options({})[:ignore].should == [' ', ',', ':', ';', '(', ')', '"', '.']
    end

    it "should add values to arrays" do 
      Example.merge_options(:ignore => 'abc')[:ignore].should ==
        [' ', ',', ':', ';', '(', ')', '"', '.', 'abc']
    end
    
    it "should add arrays to the other array" do 
      Example.merge_options(:ignore => ['abc', 'bar'])[:ignore].should ==
        [' ', ',', ':', ';', '(', ')', '"', '.', 'abc', 'bar']
    end

    it "should overwrite other values" do 
      Example.merge_options(:keep_case => true)[:keep_case].should be_true
    end
  end
  
  describe "initialize" do 
    it "should initialize correctly" do 
      x = Example.new("str1", :abc => "foo", :ignore => "something")
      x.instance_variable_get(:@str).should == "str1"
      x.instance_variable_get(:@actions).should == []
      x.instance_variable_get(:@options).should == 
        Example.merge_options(:abc => "foo", :ignore => "something")
      x.representation.should be_nil
      x.optionals.should == []
    end
  end
  
  describe "line_division" do 
    it "should return the current line division" do 
      Example.new("str1").line_division.should be_true
      Example.new("str1", :line_division => false).line_division.should be_false
    end
  end
  
  describe "action" do 
    it "should save the block given to it" do 
      block = proc { }
      x = Example.new("fo")
      x.action(&block)
      x.instance_variable_get(:@actions).should == [block]
    end
  end
  
  describe "finalize_example" do 
  end
  describe "match" do 
  end
  describe "simple_match" do 
  end
  describe "sliding_find" do 
  end
  describe "invoke_actions_with_values" do 
  end
  describe "match_values" do 
  end
  describe "masng_for_literals" do 
  end
  describe "replace_with_literals" do 
  end
  describe "typeof" do 
  end
  describe "to_type" do 
  end
  describe "find_literals" do 
  end
  describe "tokens_for" do 
  end
  describe "analyze" do 
  end

  describe "better" do 
    it "should return false if tokens are the same as representation" do 
      x = Example.new("str")
      x.send(:better, nil).should be_false
      x.instance_variable_set(:@representation, [])
      x.send(:better, []).should be_false
      x.instance_variable_set(:@representation, ["a", "b"])
      x.send(:better, ["a", "b"]).should be_false
    end

    it "should return based on the length of tokens" do 
      x = Example.new("str")
      x.instance_variable_set(:@representation, [])
      x.send(:better, ["foo"]).should be_false
      x.instance_variable_set(:@representation, ["foo"])
      x.send(:better, ["foo"]).should be_false
      x.send(:better, []).should be_true
      x.instance_variable_set(:@representation, ["foo", "bar", "quux"])
      x.send(:better, ["foo", "bar", "q"]).should be_false
      x.send(:better, ["foo", "bar"]).should be_true
      x.send(:better, ["foo"]).should be_true
      x.send(:better, []).should be_true
    end
  end

  describe "add_new_optionals" do 
    it "shouldn't do anything with empty argument and empty representation" do 
      x = Example.new("str")
      x.instance_variable_set(:@representation, [])
      x.send :add_optionals_as_intersection_of, []
      x.optionals.should == []
    end
      
    it "should make everything optional with empty argument" do 
      x = Example.new("str")
      x.instance_variable_set(:@representation, ["a", "b", "c"])
      x.send :add_optionals_as_intersection_of, []
      x.optionals.should == ["a", "b", "c"]
    end
    
    it "should make everything optional with empty representation" do 
      x = Example.new("str")
      x.instance_variable_set(:@representation, [])
      x.send :add_optionals_as_intersection_of, ["a", "b", "c"]
      x.optionals.should == ["a", "b", "c"]
    end

    it "should return all tokens that are not optional" do 
      x = Example.new("str")
      x.instance_variable_set(:@representation, ["a", "b", "c"])
      x.send(:add_optionals_as_intersection_of, ["b", "x"]).should == ["b"]
    end

    it "should only have one optional per token" do 
      x = Example.new("str")
      x.instance_variable_set(:@representation, [])
      x.send :add_optionals_as_intersection_of, ["a", "b", "c", "b"]
      x.optionals.should == ["a", "b", "c"]
    end
  end
end
