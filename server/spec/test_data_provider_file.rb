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
class DataProviderFileTest < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level = Logger::ERROR
    logger.level = Logger::DEBUG
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  ############## sample

  def test_missing_file_via_new_class

    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m, "create provider object")
    classes = m.DataProviderFileCourse("nobody", 2010, 'nowhere/at/all')
    assert_equal(404, classes.meta_status, '404 for missing class')

  end


  def test_via_struct

    # Create a struct class. Need to supply Struct constructor with some argument so
    # we are providing a name for the class.  Struct makes it easy to create a class
    # with attributes and that may be good for testing.

    m = Struct.new("ModuleTester").new

    # add the module to the class.
    class<<m
      include DataProviderFile
      include Logging
    end

    # ## do something with the class.
    # m.note("HI")
    #
    # assert_equal m.getNote, "HI", "did not find note"
    # refute_equal m.getNote, "BUY", "did not find note"
  end

  def test_wrapping_regular_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    classes = m.DataProviderFileCourse("tiny", 2010, '../test-files/courses')
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
        classes = m.DataProviderFileCourse("nobody", 2010, 'nowhere/at/all')
        puts "test_regular_wrapped_file_stubs classes:"
        p classes
        assert_equal(200, classes.meta_status, '200 for finding class')
        result = classes.result
        puts "result in double wrapping"
        p result
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
      classes = m.DataProviderFileCourse("nobody", 2010, 'nowhere/at/all')
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
        classes = m.DataProviderFileCourse("A", "B", "C")
        assert_equal(777, classes.meta_status, '404 for prewrapped file')
      end
    end
  end

  def test_pre_wrapped_regular_file

    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    classes = m.DataProviderFileCourse("meta", 2010, '../test-files/courses')
    puts "pre_wrapped"
    p classes
    assert_equal(888, classes.meta_status, '200 for finding class')
  end

  end
