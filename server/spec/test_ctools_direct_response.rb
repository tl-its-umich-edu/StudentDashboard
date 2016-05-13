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

  @@empty_response = '{"entityPrefix":"dash"}'
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
    @response = CToolsDirectResponse.new(@@empty_response, Hash.new)
    refute_nil @response, "get connector object"
    refute_nil @@testFileDir, "locate test file directory"
  end

  def test_string_A_json_todolms
    response = CToolsDirectResponse.new(@@empty_response, Hash.new)
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
    file_data_as_string = get_RESULT_json_from_file(file_name)
    response = CToolsDirectResponse.new(file_data_as_string, Hash.new)
    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms

    logger.debug "#{__method__}: #{__LINE__}: dash_format: "+dash_format.inspect
    assert_equal 2, dash_format.length, 'got multiple assignments, one filtered out'
    assert_equal 10, dash_format[0][:due_date_sort].length

  end


  def test_get_ctools_collection_multiple_keys_todolms

    # Test with sample of multiple assignments.
    # The 'ctoolsXX' files are full results, not unit test data, so:
    # read it in, strip off the WAPI wrapper, stringify it and then process.

    file_name = "assignment_multiple_keys"
    file_data_as_string = get_RESULT_json_from_file(file_name)
    response = CToolsDirectResponse.new(file_data_as_string, Hash.new)
    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms

    logger.debug "#{__method__}: #{__LINE__}: dash_format: "+dash_format.inspect
    assert_equal 13, dash_format.length, 'got multiple assignments, one filtered out'
    assert_equal 10, dash_format[0][:due_date_sort].length

  end

  def test_filter_filter_assignment_data_01
    file_name = "assignment_data_01"
    file_as_string = IO.read("#{@@testFileDir}/todolms/ctools/#{file_name}.json")

    file_data = JSON.parse(file_as_string)

    assert_equal 6, file_data.length, 'got multiple assignments'

    filtered = file_data.select { |a| CToolsDirectResponse.filter(a) }
    logger.debug "#{__method__}: #{__LINE__}: filtered: "+filtered.inspect

    assert_equal 3, filtered.length, 'filter out uninteresting assignments'

  end


  def test_filter_filter_assignment_data_no_match
    file_name = "assignment_data_no_match"
    file_as_string = IO.read("#{@@testFileDir}/todolms/ctools/#{file_name}.json")

    file_data = JSON.parse(file_as_string)

    assert_equal 5, file_data.length, 'got multiple assignments'

    filtered = file_data.select { |a| CToolsDirectResponse.filter(a) }
    logger.debug "#{__method__}: #{__LINE__}: filtered: "+filtered.inspect

    assert_equal 0, filtered.length, 'filter out uninteresting assignments'

  end

  def test_filter_filter_assignment_multiple_keys
    file_name = "assignment_multiple_keys"
    file_as_string = IO.read("#{@@testFileDir}/todolms/ctools/#{file_name}.json")

    file_data = JSON.parse(file_as_string)
    file_data = file_data['Result']['dash_collection']

    assert_equal 16, file_data.length, 'got multiple assignments'

    filtered = file_data.select { |a| CToolsDirectResponse.filter(a) }

    assert_equal 13, filtered.length, 'filter out assignments not labeled with due date'

  end

  def test_filter_filter_assignment_null

    empty_assignment = '[{}]'

    list_data = JSON.parse(empty_assignment)

    assert_equal 1, list_data.length, 'got an assignment'

    filtered = list_data.select { |a| CToolsDirectResponse.filter(a) }
    logger.debug "#{__method__}: #{__LINE__}: filtered: "+filtered.inspect

    assert_equal 0, filtered.length, 'filter out uninteresting assignments'

  end

  def test_get_ctools_collection_no_infoLinkURL

    file_name = "ctools01-noInfoLinkURL"
    file_data_as_string = get_RESULT_json_from_file(file_name)

    response = CToolsDirectResponse.new(file_data_as_string, Hash.new)
    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms

    logger.debug "#{__method__}: #{__LINE__}: dash_format: "+dash_format.inspect
    dash_format.each do |a|
      assert_nil(a[:link],"null link allowed")
    end
  end

  def get_RESULT_json_from_file(file_name)
    file_as_string = IO.read("#{@@testFileDir}/todolms/ctools/#{file_name}.json")

    file_as_json = JSON.parse(file_as_string)
    file_data = file_as_json['Result']
    file_data_as_string = JSON.generate(file_data)
  end

  # file mulitple keys for doView_submission
  # file studenta for doView_submission

  def test_get_ctools_collection_view_submission_link_url

    file_name = "unitTestAssignmentSubmission"
    file_data_as_string = get_RESULT_json_from_file(file_name)
    response = CToolsDirectResponse.new(file_data_as_string, Hash.new)
    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms

    logger.debug "#{__method__}: #{__LINE__}: dash_format: "+dash_format.inspect
    dash_format.each do |a|
      assert_match /assignmentId/,a[:link],"url has expected value assignmentId"
      assert_match /&sakai_action=doView_submission/,a[:link],"url has expected action parameter"
    end
  end

  def test_get_ctools_collection_view_assignment_link_url_new

    file_name = "unitTestAssignmentAssignment"
    file_data_as_string = get_RESULT_json_from_file(file_name)
    response = CToolsDirectResponse.new(file_data_as_string, Hash.new)
    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    dash_format = response.toDoLms

    logger.debug "#{__method__}: #{__LINE__}: dash_format: "+dash_format.inspect
    dash_format.each do |a|
      assert_match /assignmentId/,a[:link],"url has expected value assignmentId"
      assert_match /&sakai_action=doView_assignment/,a[:link],"url has expected action parameter"
    end
  end

end
