##### Demonstrate approach to testing methods in a module by constructing a tiny class
##### to contain the module.  Two different methods are shown here.
#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
# require 'webmock/minitest'
require_relative '../data_provider_file'
require_relative '../WAPI_result_wrapper'
require_relative '../Logging'


#######################################
## Create the test class
#######################################
class TestDataProviderFile < Minitest::Test

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

  def test_get_existing_course_file

    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    classes = m.dataProviderFileCourse("unitTestA", 2010, '../test-files/courses')
    assert_equal(200,classes.meta_status,'200 for existing class')

  end

  def test_get_missing_course_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    classes = m.dataProviderFileCourse("nofile at all", 2010, '../test-files/courses')
    assert_equal(404,classes.meta_status,'404 for missing class')

  end

  def test_get_course_file_2020

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    response = m.dataProviderFileCourse("gsilver", 2020, '../test-files/courses')
    assert_equal(200,response.meta_status,'404 for missing class')
    classes = response.result
    title = classes[0]['Title']
    assert_match /2020/, title, "find 2020 in course title"
  end



  def test_get_default_term_file_for_missing_term_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    terms = m.dataProviderFileTerms("nofilehere", '../test-files/terms')
    assert_equal(200,terms.meta_status,'200 for missing default term file')

  end

  def test_get_default_term_file_explicitly

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    terms = m.dataProviderFileTerms("default", '../test-files/terms')
    assert_equal(200,terms.meta_status,'200 for missing default term file')

  end

  def test_get_unittestA_term_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    terms = m.dataProviderFileTerms("unitTestA", '../test-files/terms')
    assert_equal(200,terms.meta_status,'200 for missing unitTestA term file')

    first_term = terms.result[0]["term"]
    assert_equal("defallt",first_term,"get name of first term")

  end

end
