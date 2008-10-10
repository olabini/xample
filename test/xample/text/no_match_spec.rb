require File.dirname(__FILE__) + "/../../test_helper"

describe Xample::Text::NoMatch do
  it "should be an XampleException" do 
    Xample::Text::NoMatch.should < Xample::XampleException
  end
end
