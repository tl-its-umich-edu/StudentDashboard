##### Demonstrate approach to testing methods in a module by constructing a tiny class
##### to contain the module.  Two different methods are shown here.
#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
# require 'webmock/minitest'
require_relative '../data_provider_file'
require_relative '../Logging'


#######################################
## Create the test class
#######################################
class TestModule < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_note_module_via_class_missing_file

    ### create inline class and include the module under test.
    m = Class.new do
      include DataProviderFile
      include Logging
    end.new

    refute_nil(m,"create provider object")
    classes = m.DataProviderFileCourse("nobody", 2010, 'nowhere/at/all')
    puts classes
    assert_equal(404.to_s,classes,'404 for missing class')

  end


  def test_note_module_via_struct

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

end
