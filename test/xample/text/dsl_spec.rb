require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

describe Xample::Text::DSL do 
  describe "initialize" do 
    it "should send a block along to the Examples.parse" do 
      Examples.should_receive(:parse).once.and_yield
      x = 1
      Xample::Text::DSL.new do 
        x = 2
      end
      x.should == 2
    end
    
    it "should save created examples in @examples" do 
      Examples.should_receive(:parse).once.and_return("flux")
      x = Xample::Text::DSL.new
      x.examples.should == "flux"
    end
  end
  
  describe "run" do 
    it "should be possible to run with a string" do 
      x = Xample::Text::DSL.new { xample("foo") }
      x.run("foo")
    end

    it "should be possible to run with an IO object" do 
      x = Xample::Text::DSL.new { xample("foo") }
      File.open("test/tmp_inp") do |f|
        x.run(f)
      end
    end

    it "should raise NoMatch if no match is found" do 
      x = Xample::Text::DSL.new { xample("foo") }
      proc do 
        x.run("bar")
      end.should raise_error(NoMatch)
    end

    it "should call @examples.match with the IO object" do 
      examples = mock("@examples")
      Examples.should_receive(:parse).once.and_return(examples)
      x = Xample::Text::DSL.new
      s = StringIO.new("foo")
      examples.should_receive(:match).with(s).and_return(true)
      x.run(s)
    end
  end
end
