##### Demonstrate approach to testing methods in a module by constructing a tiny class
##### to contain the module.  Two different methods are shown here.
#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
# require 'webmock/minitest'

#######################################
## Create a small module to test.
#######################################
module TrivialNoteModule
  def note(n)
    @note = n
  end

  def getNote
    @note
  end
end

#######################################
## Create the test class
#######################################
class TestModule < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level = Logger::ERROR
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_note_module_via_class

    ### create inline class and include the module under test.
    m = Class.new do
      include TrivialNoteModule
    end.new

    ## do something with module methods.
    m.note("HI")

    assert_equal m.getNote, "HI", "did not find note"
    refute_equal m.getNote, "BUY", "did not find note"
  end


  def test_note_module_via_struct

    # Create a struct class. Need to supply Struct constructor with some argument so
    # we are providing a name for the class.  Struct makes it easy to create a class
    # with attributes and that may be good for testing.

    m = Struct.new("ModuleTester").new

    # add the module to the class.
    class<<m
      include TrivialNoteModule
    end

    ## do something with the class.
    m.note("HI")

    assert_equal m.getNote, "HI", "did not find note"
    refute_equal m.getNote, "BUY", "did not find note"
  end

end
