##### Demonstrate approach to testing methods in a module by constructing a tiny class
##### to contain the module.  Two different methods are shown here.
#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
# require 'webmock/minitest'

require 'yaml'
require_relative '../data_provider_esb'
require_relative '../WAPI_result_wrapper'
require_relative '../WAPI'
require_relative '../Logging'


#######################################
## Create the test class
#######################################
class TestIntegrationDataProviderESB < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_esb_with_bad_uniqname

    skip("can not test with stubs")
    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderESB
      include Logging
      require_relative '../WAPI'
      @@w = nil
      @@yml = nil
    end.new

    refute_nil(m,"create provider object")
    classes = m.DataProviderESBCourse("nobody.XXX", "2010", "./security.yml","ESB-QA","2010")
    assert_equal(404,classes.meta_status,'response not completed (will fail when stubbed)')
    assert_equal(404,JSON.parse(classes.result)['responseCode'],'should not find (missing) user.')

  end

  def test_esb_terms

    # current sub response 2014/12/08
    # {
    #     "getMyRegTermsResponse": {
    #     "Term": {
    #     "TermCode": "1960",
    #     "TermDescr": "Fall 2014",
    #     "TermShortDescr": "FA 2014"
    # }
    # }
    # }

    skip("not yet testable")
    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderESB
      include Logging
      require_relative '../WAPI'
      @@w = nil
      @@yml = nil
    end.new

    refute_nil(m,"create provider object")
    terms = m.DataProviderESBTerms("ststvii", "2010", "./security.yml","SD-QA","2010")
    assert_equal(404,terms.meta_status,'response not completed (will fail when stubbed)')
    assert_equal(404,JSON.parse(terms.result)['responseCode'],'should not find (missing) user.')

  end


  # def test_note_module_via_struct
  #
  #   # Create a struct class. Need to supply Struct constructor with some argument so
  #   # we are providing a name for the class.  Struct makes it easy to create a class
  #   # with attributes and that may be good for testing.
  #
  #   m = Struct.new("ModuleTester",@@w,@@yml).new
  #
  #   # add the module to the class.
  #   class<<m
  #     include DataProviderESB
  #     include Logging
  #     @@w = "HI"
  #     @@yml = nil
  #   end
  #
  #   # ## do something with the class.
  #   # m.note("HI")
  #   #
  #   # assert_equal m.getNote, "HI", "did not find note"
  #   # refute_equal m.getNote, "BUY", "did not find note"
  #   assert_equal(m.@@w,"x")
  # end

end
