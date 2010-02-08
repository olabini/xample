require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

include Xample::Text

describe Examples do 
  it "should mixin Enumerable" do 
    Examples.ancestors.should include(Enumerable)
  end
  
  it "should have an each method that calls examples.each" do 
    one = 1
    x = Examples.new
    ex = mock("examples")
    ex.should_receive(:each).and_yield
    x.should_receive(:examples).and_return(ex)
    x.each do 
      one += 1
    end
    one.should == 2
  end

  describe "parse" do 
    it "should instance_eval block sent into it" do 
      ex = Examples.new
      Examples.should_receive(:new).and_return(ex)
      Examples.parse do 
        self.object_id.should == ex.object_id
      end.should == ex
    end
    
    it "should finalize all examples created" do 
      ex = Examples.new
      Examples.should_receive(:new).and_return(ex)

      x1 = mock("example one")
      x1.should_receive(:finalize_example)

      x2 = mock("example two")
      x2.should_receive(:finalize_example)
      
      ex.should_receive(:examples).and_return([x1,x2])

      Examples.parse do 
      end
    end
  end

  describe "xample" do 
    it "should be able to accept a string" do 
      xs = Examples.new
      x = xs.xample("foo")
      xs.examples.should == [x]
    end
    
    it "should be able to accept an IO object" do 
      xs = Examples.new
      x = nil
      File.open(File.join(File.dirname(__FILE__), "..", "..", "tmp_inp")) do |f|
        x = xs.xample(f)
      end
      xs.examples.should == [x]
    end
    
    it "should create a new example for the argument" do 
      xs = Examples.new
      mockx = mock("Example")
      Example.should_receive(:new).with("foo").and_return(mockx)
      xs.xample("foo").should == mockx
      xs.examples.should == [mockx]
    end
  end

  describe "match" do 
    it "should read from it's argument" do 
      io = mock("io")
      io.should_receive(:read)
      Examples.new.match(io)
    end
    
    it "should call match on all examples if no match is found" do 
      io = stub("io", :read => "flurg")
      x1 = mock("example 1")
      x1.should_receive(:match).with("flurg").and_return(false)
      x2 = mock("example 2")
      x2.should_receive(:match).with("flurg").and_return(false)
      
      x = Examples.new
      x.should_receive(:examples).and_return([x1,x2])
      x.match(io).should be_false
    end

    it "should call match on all examples until match is found" do 
      io = stub("io", :read => "flurg")
      x1 = mock("example 1")
      x1.should_receive(:match).with("flurg").and_return(false)

      x2 = mock("example 2")
      x2.should_receive(:match).with("flurg").and_return(true)

      x3 = mock("example 3")
      
      x = Examples.new
      x.should_receive(:examples).and_return([x1,x2,x3])
      x.match(io).should be_true
    end
  end
end
