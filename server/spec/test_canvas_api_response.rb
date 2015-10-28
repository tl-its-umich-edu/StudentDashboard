## Unit tests for Canvas API feed class

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require 'logger'

require_relative '../Logging'
require_relative 'test_helper'
require_relative '../canvas_api_response'

include Logging

# test that can process the data from the Canvas direct feed.
# It should work with any channel for getting the data.

class TestCanvasAPIResponse < Minitest::Test

  @@string_A = '[]'
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

    assert_equal 'canvas', entry[:contextLMS], "set proper lms context"

    refute_nil entry[:contextUrl], "have context url"
    refute_nil entry[:link], "have link value"
    refute_nil entry[:context], "have context"
    refute_nil entry[:id], "have id"
    refute_nil entry[:description], "have non-nil description"
  end

  # verify that processing the minimal string version works
  def test_new_creates_something
    @response = CanvasAPIResponse.new(@@string_A,Hash.new())
    refute_nil @response, "get object"
    refute_nil @@testFileDir, "locate test file directory"
  end

  def test_string_A_json_todolms
    response = CanvasAPIResponse.new(@@string_A,Hash.new())
    tdl = response.toDoLms
    assert_equal 0, tdl.length,"verify length of empty response"
  end

  # verify can read json from a file.
  def test_get_canvas_json_data_todolms
    file_name = "studenta"
    file_name = IO.read("#{@@testFileDir}/todolms/canvas/#{file_name}.json")
    refute_nil file_name, "find test file"
    jsonA = JSON.parse(file_name)
    refute_nil jsonA, "check that file contents are understood as json"
  end

  def test_get_canvas_collection_todolms

    # Test with sample of multiple assignments.
    # The test files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "studenta"
    file_as_string = IO.read("#{@@testFileDir}/todolms/canvas/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
    response = CanvasAPIResponse.new(file_data_as_string,Hash.new())

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: dash_format: "+dash_format.to_json

    assert_equal 9,dash_format.length,"get multiple events"

    # get the first entry
    verify_event(dash_format[0])

    dash_format.map {|event| verify_event event}

    # TODO:
    # test due date of some sort
    # test assignment information
    # test grade and grade_type

      logger.debug "#{__method__}: #{__LINE__}: C: dash_format: "+dash_format.inspect
  end


  def test_get_canvas_assignment_event

    # Test single entry with an assignment
    # The test files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "assignment_A"
    file_as_string = IO.read("#{@@testFileDir}/todolms/canvas/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
    response = CanvasAPIResponse.new(file_data_as_string,Hash.new())

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: dash_format: "+dash_format.to_json

    assert_equal 1,dash_format.length,"get multiple events"

    # extract out the single entry
    event = dash_format.pop
    verify_event event

    # verify that some assignment specific processing took place.
    assert_equal "points",event[:grade_type], "has grade type"

    assert_equal "1445313599",event[:due_date_sort]

    # TODO:
    # test due date of some sort

    logger.debug "#{__method__}: #{__LINE__}: C: dash_format: "+dash_format.inspect
  end

  def test_get_canvas_no_assignment_event

    # Test single entry with an assignment
    # The test files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "no_assignment"
    file_as_string = IO.read("#{@@testFileDir}/todolms/canvas/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
    response = CanvasAPIResponse.new(file_data_as_string,Hash.new())

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: dash_format: "+dash_format.to_json

    assert_equal 1,dash_format.length,"get multiple events"

    # extract out the single entry
    event = dash_format.pop
    verify_event event


    #assert_equal 123,event[:]
    assert_nil event[:due_date_sort],"no due date"
    #assert_equal 1445313599,event[:due_date_sort]

    # TODO:
    # test due date of some sort

    logger.debug "#{__method__}: #{__LINE__}: C: dash_format: "+dash_format.inspect
  end


  def test_get_canvas_assignment_replace_event

    # Test single entry with an assignment
    # The test files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "assignment_A"
    file_as_string = IO.read("#{@@testFileDir}/todolms/canvas/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
    stringReplace = Hash.new()
    stringReplace['link'] = ["https://api-qa-gw.its.umich.edu","https://umich.test.instructure.com"]
    stringReplace['contextUrl'] = ["CANVAS_INSTANCE_PREFIX","https://umich.test.instructure.com"]

    logger.debug "#{__method__}: #{__LINE__}: input: "+file_data_as_string.inspect
    response = CanvasAPIResponse.new(file_data_as_string,stringReplace)

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: dash_format: "+dash_format.to_json

    assert_equal 1,dash_format.length,"get multiple events"
    assert_equal "https://umich.test.instructure.com/courses/15572/assignments/23762",dash_format[0][:link],"reset link url"

    # extract out the single entry
    event = dash_format.pop
    verify_event event

    # verify that some assignment specific processing took place.
    assert_equal "points",event[:grade_type], "has grade type"

    assert_equal "1445313599",event[:due_date_sort]

    logger.debug "#{__method__}: #{__LINE__}: C: dash_format: "+dash_format.inspect
  end

end
