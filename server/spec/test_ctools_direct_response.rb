## Unit tests for ctools direct feed class

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require 'logger'

require_relative '../Logging'
require_relative 'test_helper'
require_relative '../ctools_direct_response'

include Logging

# test that can process the data from the ctools direct feed.
# It should work with any channel for getting the data.

class TestCtoolsDirectResponse < Minitest::Test

  @@string_A = '{"entityPrefix":"dash"}'
  @@testFileDir = TestHelper.findTestFileDirectory

  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=TestHelper.getCommonLogLevel
    # allow for file by file override
    #logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG

  end

  # verify that processing the minimal string version works
  def test_new_creates_something
    @response = CToolsDirectResponse.new(@@string_A)
    refute_nil @response, "get connector object"
    refute_nil @@testFileDir, "locate test file directory"
  end

  def test_string_A_json_todolms
    response = CToolsDirectResponse.new(@@string_A)
    tdl = response.toDoLms
    assert_equal 0, tdl.length, "verify length of empty response"
  end

  # verify can read json from a file.
  def test_get_ctools_json_data_todolms
    file_name = "ctools01"
    file_name = IO.read("#{@@testFileDir}/todolms/ctools/#{file_name}.json")
    refute_nil file_name, "find test file"
    jsonA = JSON.parse(file_name)
    refute_nil jsonA, "check that file contents are understood as json"
  end

  def test_get_ctools_collection_todolms

    # Test with sample of multiple assignments.
    # The 'ctoolsXX' files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "ctools01"
    file_as_string = IO.read("#{@@testFileDir}/todolms/ctools/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
    response = CToolsDirectResponse.new(file_data_as_string)
    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms

    assert_equal 3, dash_format.length, 'got multiple assignments'
    assert_equal 10, dash_format[0][:due_date_sort].length
    logger.debug "#{__method__}: #{__LINE__}: dash_format: "+dash_format.inspect
  end

end
