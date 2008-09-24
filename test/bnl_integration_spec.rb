require File.dirname(__FILE__) + "/test_helper"

describe Xample::Text::DSL, "BNL" do 
  it "should have a correct representation" do 
    Xample::Tests::BNL.examples.map { |x| x.representation }.should == 
      [["bonus",
        [:literal, :sym, 2],
        [:literal, :int, 1],
        [:divided_literal, true, 0, 0],
        [:divided_literal, false, 0, 1],
        "last",
        [:literal, :int, 3],
        "months",
        [:literal, :str, 4],
        [:literal, :str, 5]],
       ["bonus",
        [:literal, :sym, 2],
        [:literal, :int, 1],
        [:divided_literal, true, 0, 0],
        [:divided_literal, false, 0, 1],
        [:divided_literal, true, 4, 0],
        [:divided_literal, false, 4, 1],
        [:literal, :int, 5],
        "people",
        [:literal, :str, 3],
        [:literal, :str, 6],
        [:literal, :str, 7]]]

    Xample::Tests::BNL.examples.map { |x| x.optionals }.should == 
      [["for", "each", "as", "of", "the", "in"], 
       ["for", "with", "in"]]
  end
  
  it "should recognize simple examples and call create" do 
    BonusRegistration2.should_receive(:create).once.with(7300, "$").and_return(Swallower.instance)
    Xample::Tests::BNL.run(<<DSL)
bonus $7,300 for each new account as of the last 4 months, payable in May
DSL
  end
  
  it "should call new account with correct parameters" do 
    mock = mock("RegistrationResult")
    mock.should_receive(:new_account).once.with(4, :payable => "May")
    BonusRegistration2.stub!(:create).and_return(mock)
    Xample::Tests::BNL.run(<<DSL)
bonus $7,300 for each new account as of the last 4 months, payable in May
DSL
  end

  it "should call new account with correct parameters when called with less parts" do 
    mock = mock("RegistrationResult")
    mock.should_receive(:new_account).once.with(5, :payable => "April")
    BonusRegistration2.stub!(:create).and_return(mock)
    Xample::Tests::BNL.run(<<DSL)
bonus $1200 each new account last 5 months, payable April
DSL
  end
end
