#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

## Verify that the regex used for a path in Sinatra matches expected paths.\
## Need to add the regex and test paths explicitly.  This does not extract
## paths from you Sinatra application.

class TestPathRegex < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    #@regex = /\/self(\Z|(\/|\/[\w\/]+)?(\.json)?)$/ ## WORKS, but restricted to json
    @regex = /\/self(\Z|(\/|\/[\w\/]+)?(\.\w+)?)$/ ## WORKS
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end


  # check trailing self
  def test_terminal_self
    assert_match @regex, '/todolms/self/', "match self element and trailing slash"
    assert_match @regex, '/todolms/self', "match trailing self element"
  end

  # check simple suffix
  def test_suffix_self

    assert_match @regex, '/todolms/self.json', "match with extension"

  end

  def test_other_self

    assert_match @regex, '/todolms/self/ctools', "match with sub element, no extension"
    assert_match @regex, '/todolms/self/ctools.json', "match with sub element and extension"

  end

  def test_do_not_match
    refute_match @regex, '/todolms/selfXXX/ctools.json', "don't match if self is part of another string"
    refute_match @regex, '/todolms/YYYselfXXX/ctools.json', "don't match if self is part of another string"
  end

  def test_others
    assert_match @regex, '/todolms/self.json', "match with extension"
    assert_match @regex, '/todolms/self/canvas', "match with just source"
    assert_match @regex, '/todolms/self/ctools.json', "match source and extension"
  end

end
