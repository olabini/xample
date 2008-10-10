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
      x.instance_variable_get(:@parsed_actions).should == []
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
  
  describe "analyze_lines!" do 
    it "should not do anything if not line_division" do 
      str = mock("str")
      x = Example.new(str)
      x.should_receive(:line_division).and_return(false)
      x.analyze_lines!
    end

    it "should process each line of string if line division" do 
      str = mock("str")
      x = Example.new(str)
      x.should_receive(:line_division).and_return(true)
      str.should_receive(:each_line)
      x.analyze_lines!
    end

    it "should not do anything with empty lines" do 
      x = Example.new("\n \n  \n\t\n     \t\f  ")
      x.should_receive(:line_division).and_return(true)
      x.should_not_receive(:analyze)
      x.analyze_lines!
    end
    
    it "should analyze everything except empty lines" do 
      x = Example.new("a\nb\nc \n\n d ")
      x.should_receive(:line_division).and_return(true)
      x.should_receive(:analyze).once.with("a").ordered
      x.should_receive(:analyze).once.with("b").ordered
      x.should_receive(:analyze).once.with("c").ordered
      x.should_receive(:analyze).once.with("d").ordered
      x.analyze_lines!
    end
  end

  describe "parse_tree_for" do 
    it "should return only the block part of a parse tree" do 
      Example.new("").parse_tree_for(proc{ 1 }).should == 
        [:lit, 1]
      Example.new("").parse_tree_for(proc{ |x| puts x }).should == 
        [:fcall, :puts, [:array, [:dvar, :x]]]
    end
  end
  
  describe "find_possible_literals_in_code" do 
    it "should find all possible literals" do 
      x = Example.new("str")
      tree = [:call, [:call, [:const, :BonusRegistration], :create, [:array, [:lit, 1000], [:str, "$"]]], :on_new_account]
      x.should_receive(:parse_tree_for).and_return(tree)
      x.find_possible_literals_in_code(proc{ }).should == ["on_new_account", ["on", "new", "account"], "create", "1000", "$"]
      x.instance_variable_get(:@parsed_actions).should == [tree]
    end
  end

  describe "raw_literal?" do 
    it "should recognize anything from @representation"
  end

  describe "divided_literal?" do 
    it "should recognize any array" do 
      Example.new("str").divided_literal?("fo").should be_false
      Example.new("str").divided_literal?(nil).should be_false
      Example.new("str").divided_literal?(:x).should be_false
      Example.new("str").divided_literal?([]).should be_true
      Example.new("str").divided_literal?([:literal]).should be_true
      Example.new("str").divided_literal?([:literal, 1]).should be_true
      Example.new("str").divided_literal?([:divided_literal, 1]).should be_true
      Example.new("str").divided_literal?(["slurg"]).should be_true
    end
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
