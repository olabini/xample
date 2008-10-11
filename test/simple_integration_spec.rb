require File.expand_path(File.dirname(__FILE__) + "/test_helper")

describe Xample::Text::DSL, "SimpleBonus" do 
  it "should invoke correct method with simple parameters" do 
    BonusRegistration.should_receive(:create).once.with(42, "$").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: $42 on new account
DATA
  end

  it "should invoke correct method with simple parameters and lots of noise words" do 
    BonusRegistration.should_receive(:create).once.with(42, "$").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: $42 on each (new) account
DATA
  end
  
  it "should invoke correct method with simple parameters with variations in case" do 
    BonusRegistration.should_receive(:create).once.with(43, "$").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
BONUS: $43 on new account
DATA
  end
  
  it "should invoke correct method with simple parameters with variations in characters" do 
    BonusRegistration.should_receive(:create).once.with(42, "$").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus $42    on                           new account
DATA
  end
  
  it "should invoke correct method with another set of parameters with noise in dsl" do 
    BonusRegistration.should_receive(:create).once.with(123, "%").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %123 (per new account)
DATA
  end

  it "should match more complicated expression and still return right value" do 
    BonusRegistration.should_receive(:create).once.with(123, "%").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %123 (per existing account)
DATA
  end

  it "should match more complicated expression twice and still return right value" do 
    BonusRegistration.should_receive(:create).twice.with(123, "%").and_return(Swallower.instance)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %123 (per existing account)
bonus: %123 (per existing account)
DATA
  end

  it "should invoke partial method based on template" do 
    mock = mock("RegistrationResult")
    mock.should_receive :on_existing_account
    BonusRegistration.stub!(:create).and_return(mock)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %123 (per existing account)
DATA
  end

  it "should invoke another partial method based on template, although lower cased" do 
    mock = mock("RegistrationResult")
    mock.should_receive :on_new_account
    BonusRegistration.stub!(:create).and_return(mock)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %321 (per NEW account)
DATA
  end

  it "should invoke partial method based on template with another name" do 
    mock = mock("RegistrationResult")
    mock.should_receive :on_full_account
    BonusRegistration.stub!(:create).and_return(mock)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %321 (per full account)
DATA
  end

  it "should invoke partial method based on template several times" do 
    mock = mock("RegistrationResult")
    mock.should_receive(:on_new_account).twice
    BonusRegistration.stub!(:create).and_return(mock)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: %123 (per new account)
bonus: %321 (per new account)
DATA
  end

  it "should raise exception when it couldn't match any template" do 
    proc do 
      Xample::Tests::SimpleBonus.run(<<DATA)
bonus: 123$ per new account
DATA
    end.should raise_error(Xample::Text::NoMatch)
  end
end
