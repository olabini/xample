
require File.dirname(__FILE__) + "/test_helper"

Expectations do 
  expect BonusRegistration.to.receive(:create).with(42, "$") do |out|
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: $42 on new account
DATA
  end

  expect BonusRegistration.to.receive(:create).with(123, "£") do |out|
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £123 (per new account)
DATA
  end

  expect BonusRegistration.to.receive(:create).with(123, "£") do |out|
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £123 (per existing account)
DATA
  end

  expect BonusRegistration.to.receive(:create).with(123, "£").times(2) do |out|
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £123 (per existing account)
bonus: £123 (per existing account)
DATA
  end

  expect mock.to.receive(:on_existing_account) do |result|
    BonusRegistration.stubs(:create).returns(result)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £123 (per existing account)
DATA
  end  

  expect mock.to.receive(:on_new_account) do |result|
    BonusRegistration.stubs(:create).returns(result)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £321 (per NEW account)
DATA
  end  

  expect mock.to.receive(:on_full_account) do |result|
    BonusRegistration.stubs(:create).returns(result)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £321 (per full account)
DATA
  end  

  expect mock.to.receive(:on_new_account).times(2) do |result|
    BonusRegistration.stubs(:create).returns(result)
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: £123 (per new account)
bonus: £321 (per new account)
DATA
  end  

  expect Xample::Text::NoMatch do |out|
    Xample::Tests::SimpleBonus.run(<<DATA)
bonus: 123$ (per new account)
DATA
  end
end
