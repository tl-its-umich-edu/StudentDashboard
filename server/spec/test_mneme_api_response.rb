## Unit tests for mneme API feed class

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require 'logger'

require_relative '../Logging'
require_relative 'test_helper'
require_relative '../mneme_api_response'

include Logging

# test that can process the data from the ctools mneme direct feed.
# It should work with any channel for getting the data.

class TestMnemeAPIResponse < Minitest::Test

  @@string_A = '{"entityPrefix":"mneme"}'
  @@testFileDir = TestHelper.findTestFileDirectory

  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=TestHelper.getCommonLogLevel
    # allow for file by file override
    #logger.level=Logger::ERROR
    logger.level=Logger::DEBUG

  end

  def verify_event(entry)

    refute_nil entry[:title], "have title"

    assert_equal 'ctools', entry[:contextLMS], "set proper lms context"

    refute_nil entry[:contextUrl], "have context url"
    refute_nil entry[:link], "have link value"
    refute_nil entry[:context], "have context"
    refute_nil entry[:title], "have title"

  end

  # verify that processing the minimal string version works
  def test_new_creates_something
    @response = MnemeAPIResponse.new(@@string_A)
    refute_nil @response, "get object"
    refute_nil @@testFileDir, "locate test file directory"
  end

  def test_string_A_json_todolms
    response = MnemeAPIResponse.new(@@string_A)
    tdl = response.toDoLms
    assert_equal 0, tdl.length,"verify length of empty response"
  end

  # verify can read json from a file.
  def test_get_mneme_json_data_todolms
    file_name = "studenta"
    file_name = IO.read("#{@@testFileDir}/todolms/mneme/#{file_name}.json")
    refute_nil file_name, "find test file"
    jsonA = JSON.parse(file_name)
    refute_nil jsonA, "check that file contents are understood as json"
  end

  def test_get_mneme_collection_todolms

    # Test with sample of multiple assignments.
    # The test files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "studenta"
    file_as_string = IO.read("#{@@testFileDir}/todolms/mneme/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    puts "file_data: #{file_data}"
    file_data_as_string = JSON.generate(file_data)
    response = MnemeAPIResponse.new(file_data_as_string)

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    mneme_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: mneme_format: "+mneme_format.to_json

    assert_operator 1, "<",mneme_format.length,"get multiple events"

    # get the first entry
    verify_event(mneme_format[0])

    mneme_format.map {|event| verify_event event}

    # TODO:
    # test due date of some sort
    # test assignment information
    # test grade and grade_type

      logger.debug "#{__method__}: #{__LINE__}: C: mneme_format: "+mneme_format.inspect
  end


  def test_get_mneme_assignment_event

    # Test single entry with an assignment
    # The test files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "assignment_A"
    file_as_string = IO.read("#{@@testFileDir}/todolms/mneme/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
    response = MnemeAPIResponse.new(file_data_as_string)

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    mneme_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: mneme_format: "+mneme_format.to_json

    assert_equal 1,mneme_format.length,"get one event"

    # extract out the single entry
    event = mneme_format.pop
    verify_event event

    assert_equal "1417150740",event[:due_date_sort]

    logger.debug "#{__method__}: #{__LINE__}: C: mneme_format: "+mneme_format.inspect
  end

end
