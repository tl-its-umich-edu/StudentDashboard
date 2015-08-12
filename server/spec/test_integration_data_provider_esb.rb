
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require 'yaml'
require_relative '../data_provider_esb'
require_relative '../WAPI_result_wrapper'
require_relative '../Logging'
require_relative 'test_helper'


#######################################
## Create the test class
#######################################
class TestIntegrationDataProviderESB < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG

    @esb_application = "SD-QA"

    @security_file = TestHelper.findSecurityFile "security.yml"

    # may need to change this depending on the current state of the db.
    @known_uniqname = "ststvii"
    @default_term = "2060"

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_esb_with_good_uniqname

    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderESB
      include Logging
      require_relative '../WAPI'
      @@w = nil
      @@yml = nil
    end.new

    refute_nil(m,"create provider object")
    classes = m.dataProviderESBCourse(@known_uniqname, @default_term, @security_file,@esb_application,@default_term)
    assert_equal(200,classes.meta_status,'find classes for good uniqname')

  end

  def test_esb_with_bad_uniqname

    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderESB
      include Logging
      require_relative '../WAPI'
      @@w = nil
      @@yml = nil
    end.new

    skip("KNOWN TO FAIL: TLPORTAL-176")
    refute_nil(m,"create provider object")
    classes = m.dataProviderESBCourse(@known_uniqname+"XXX", @default_term, @security_file,@esb_application,@default_term)

    assert_equal(404,classes.meta_status,'response not completed (will fail when stubbed)')
    assert_equal(404,JSON.parse(classes.result)['responseCode'],'should not find (missing) user.')

  end

  def test_esb_terms

    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderESB
      include Logging
      require_relative '../WAPI'
      @@w = nil
      @@yml = nil
    end.new

    refute_nil(m,"create provider object")
    terms = m.dataProviderESBTerms(@known_uniqname, @security_file,@esb_application)
    assert_equal(200,terms.meta_status,'find terms json meta status')
    t = terms.result

    assert(t.length > 0,"found some terms")

  end


  def test_esb_no_terms

    skip("known to fail for 208 merge address with another jira")
    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderESB
      include Logging
      require_relative '../WAPI'
      @@w = nil
      @@yml = nil
    end.new

    refute_nil(m,"create provider object")
    terms = m.dataProviderESBTerms("xxx", @security_file,@esb_application)
    assert_equal(WAPI::UNKNOWN_ERROR,terms.meta_status,'get bad result for missing uniqname')
    logger.debug "terms: "+terms.inspect
    t = terms.result
    assert(t.length == 0,"get empty array when no terms")

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
