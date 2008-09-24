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
end
