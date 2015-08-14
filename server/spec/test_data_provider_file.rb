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
require_relative 'test_helper'


#######################################
## Create the test class
#######################################
class TestDataProviderFile < Minitest::Test

  attr_accessor :resources_dir
  attr_accessor :terms_dir
  attr_accessor :courses_dir

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG

    ## Resolve test directory regardless of where the tests
    ## are started.
    test_file_dir = TestHelper.findTestFileDirectory()
    @resources_dir = test_file_dir+"/resources"
    @terms_dir = test_file_dir+ "/terms"
    @courses_dir = test_file_dir+"/courses"

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

    refute_nil(m, "create provider object")
    classes = m.dataProviderFileCourse("unitTestA", 2010, @courses_dir)
    assert_equal(200, classes.meta_status, '200 for existing class')

  end

  def test_get_missing_course_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m, "create provider object")
    classes = m.dataProviderFileCourse("nofile at all", 2010, @courses_dir)
    assert_equal(404, classes.meta_status, '404 for missing class')

  end

  def test_get_course_file_2020

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m, "create provider object")
    response = m.dataProviderFileCourse("gsilver", 2020, @courses_dir)
    assert_equal(200, response.meta_status, '404 for missing class')
    result = response.result
    classes = JSON.parse(result)
    title = classes[0]['Title']
    assert_match /2020/, title, "find 2020 in course title"
  end


  def test_get_default_term_file_for_missing_term_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m, "create provider object")
    terms = m.dataProviderFileTerms("nofilehere", @terms_dir)
    assert_equal(200, terms.meta_status, '200 for missing default term file')

  end

  def test_get_default_term_file_explicitly

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m, "create provider object")
    terms = m.dataProviderFileTerms("default", @terms_dir)
    assert_equal(200, terms.meta_status, '200 for missing default term file')

  end

  # def test_get_unittestA_term_file
  #
  #   m = Class.new do
  #     include DataProviderFile
  #     include Logging
  #   end.new
  #
  #   refute_nil(m, "create provider object")
  #   terms = m.dataProviderFileTerms("unitTestA", '../test-files/terms')
  #   assert_equal(200, terms.meta_status, '200 for missing unitTestA term file')
  #
  #   first_term = terms.result[0]["term"]
  #   assert_equal("defallt", first_term, "get name of first term")
  #
  # end

  def test_wrapping_regular_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    classes = m.dataProviderFileCourse("tiny", 2010, @courses_dir)
    assert_equal(200, classes.meta_status, '200 for finding class')
  end

  ######## test with stubs

  ##### Using stubs
  #
  def test_regular_wrapped_file_stubs

    good_file = '[ {"Title": "AMCULT 217"}]';

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    ## the stub method will override calls in the block.
    File.stub :read, good_file do
      File.stub :exists?, true do
        classes = m.dataProviderFileCourse("nobody", 2010, 'nowhere/at/all')
        assert_equal(200, classes.meta_status, '200 for finding class')
        result = classes.result
        refute_instance_of WAPIResultWrapper, result, "double wrapped class"
      end
    end
  end

  def test_regular_file_missing
    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    File.stub :exists?, false do
      classes = m.dataProviderFileCourse("nobody", 2010, 'nowhere/at/all')
      assert_equal(404, classes.meta_status, '404 for missing class')
    end
    # end

  end

  ##
  #@value={"Meta"=>{"httpStatus"=>404, "Message"=>"File not found"}, "Result"=>"Data provider from files did not find a matching file for nowhere/at/all/nobody.json"}
  def test_pre_wrapped_file
    pre_wrapped_file='{"Meta": {"httpStatus":777, "Message":"File not found"}, "Result":"pre wrapped file"}'
    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    File.stub :exists?, true do
      File.stub :read, pre_wrapped_file do
        classes = m.dataProviderFileCourse("A", "B", "C")
        assert_equal(777, classes.meta_status, '404 for prewrapped file')
      end
    end
  end

  def test_pre_wrapped_regular_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    classes = m.dataProviderFileCourse("meta200", 2010, @courses_dir)
    assert_equal(200, classes.meta_status, '200 for finding class')
  end

end
