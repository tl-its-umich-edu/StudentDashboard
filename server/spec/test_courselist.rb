# Unit test checks that can veto in appropriate users
# from get information on other people.


require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require 'rest-client'
require 'logger'
require 'yaml'
require '../courselist'
## set the environment for testing
#ENV['RACK_ENV'] = 'unit'



class AuthCheck < MiniTest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # by default assume the tests will run well and don't need
    # detailed log messages

    logger.level = Logger::ERROR

    ## create a Latte application
    ## The ! should get rid of the middle ware.
    @x = CourseList.new!

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_create
    assert @x, "did not create Latte object"
  end

  def test_getTerm
    stub_request(:get, "https://api.edu/WSO2/Students/BitterDancer/Terms").
        with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer sweet!'}).
        to_return(:status => 200, :body => '{"mystuff":"yourstuff"}')
    @x.get("/")
  end
  #def test_create
#    assert @x, "did not create Latte object"
#  end



end