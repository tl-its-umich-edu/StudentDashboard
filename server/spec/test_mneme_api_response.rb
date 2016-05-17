## Unit tests for mneme API feed class

require 'minitest'
require 'minitest/mock'
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

# Using singleton method to mock out the now method for testing.
# See the test_mock_time example.

class TestMnemeAPIResponse < Minitest::Test

  @@empty_response = '{"entityPrefix":"mneme"}'
  @@testFileDir = TestHelper.findTestFileDirectory


  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=TestHelper.getCommonLogLevel
    # allow for file by file override
    #logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG
    @mock_today_epoch = 1417409940
    @seconds_per_day = 60*60*24

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
    @response = MnemeAPIResponse.new(@@empty_response)
    refute_nil @response, "get object"
    refute_nil @@testFileDir, "locate test file directory"
  end

  def test_string_A_json_todolms
    response = MnemeAPIResponse.new(@@empty_response)
    tdl = response.toDoLms
    assert_equal 0, tdl.length, "verify length of empty response"
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

    file_data_as_string = JSON.generate(file_data)
    response = MnemeAPIResponse.new(file_data_as_string)

    logger.debug "#{__method__}: #{__LINE__}: response: "+response.inspect
    mneme_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: mneme_format: "+mneme_format.to_json

    #    assert_operator 1, "<", mneme_format.length, "get multiple events"

    # get the first entry
    verify_event(mneme_format[0])

    mneme_format.map { |event| verify_event event }

    # TODO:
    # test due date of some sort
    # test assignment information
    # test grade and grade_type

    logger.debug "#{__method__}: #{__LINE__}: C: mneme_format: "+mneme_format.inspect
  end


  # testing using the full class
  def test_get_mneme_assignment_event_close_slack_ok

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

    ## redefine now for this instance to be within the close date slack.
    def response.now()
      return 1417150740+3600
    end

    mneme_format = response.toDoLms
    logger.debug "#{__method__}: #{__LINE__}: A: mneme_format: "+mneme_format.to_json

    assert_equal 1, mneme_format.length, "get one event"

    # extract out the single entry
    event = mneme_format.pop
    verify_event event

    assert_equal 1417150740, event[:due_date_sort]

    logger.debug "#{__method__}: #{__LINE__}: C: mneme_format: "+mneme_format.inspect
  end

  ################## FILTERING #########################
  ########### filtering - check published ##############
  # has been published
  def test_filter_mneme_assignment_published_and_open

    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch
    }

    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    refute_nil r, "accepted published open assignment"
  end

  def test_filter_mneme_assignment_published_but_in_future

    assign_hash = {
        'published' => true,
        'openDate' => 10}

    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect

    assert_nil r, "skipped published not open assignment"
  end

  def test_filter_mneme_assignment_published_is_bad_string

    assign_hash = {
        'published' => "HAPPYdance",
        'openDate' => 1}

    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    assert_nil r, "skip bad published value"
  end

  # no published status
  def test_filter_mneme_assignment_no_value
    assign_hash = Hash.new()
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    assert_nil r, "skip no values"
  end

  # explicitly not published
  def test_filter_mneme_assignment_not_published
    assign_hash = {'published' => false}
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    assert_nil r, "skip unpublished"
  end

  ########### filtering - check open date ##############
  def test_filter_mneme_assignment_open_in_past
    assign_hash = {
        'published' => true,
        'openDate' => @mock_today_epoch - 1000,
        'closeDate' => @mock_today_epoch
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    refute_nil r, "keep open date in past"
  end

  def test_filter_mneme_assignment_open_in_future
    assign_hash = {
        'published' => true,
        'openDate' => @mock_today_epoch + 1000
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    assert_nil r, "skip open date in future"
  end

  def test_filter_mneme_assignment_open_is_nil
    assign_hash = {
        'published' => true,
        'openDate' => nil
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    assert_nil r, "skip open date is nil"
  end


  #################### filtering - check close date #################

  def test_filter_mneme_assignment_close_date_future

    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch*2
    }

    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    refute_nil r, "keep close date in future"
  end

  def test_filter_mneme_assignment_close_date_yesterday

    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch - @seconds_per_day
    }

    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, 0)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    refute_nil r, "keep close date yesterday"
  end

  def test_filter_mneme_assignment_close_date_2weeks_ago

    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch - (14 * @seconds_per_day)
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    assert_nil r, "skip if close date two weeks in past"
  end


  def test_filter_mneme_assignment_close_date_6days_ago

    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch - (6 * @seconds_per_day)
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    refute_nil r, "keep if close date 6 days in past"
  end

  def test_filter_mneme_assignment_close_date_tomorrow

    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch + (1 * @seconds_per_day)
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    refute_nil r, "keep if close date tomorrow"
  end

  def test_filter_mneme_assignment_close_date_7days_ago
    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch - (7 * @seconds_per_day)
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    refute_nil r, "keep if close date  7 days ago"
  end

  def test_filter_mneme_assignment_close_date_7days_1sec_ago
    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch - ((7 * @seconds_per_day) + 1)
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    assert_nil r, "skip if close date more than 7 days ago"
  end

  def test_filter_mneme_assignment_close_date_1sec_future
    assign_hash = {
        'published' => true,
        'openDate' => 0,
        'closeDate' => @mock_today_epoch + 1
    }
    r = MnemeAPIResponse.filter_out_irrelevant_assignments(assign_hash, @mock_today_epoch)
    logger.debug "#{__method__}: #{__LINE__}: filter mneme: r "+r.inspect
    refute_nil r, "keep if close date even 1 sec in future"
  end

  # def test_mock_time
  #   r = MnemeAPIResponse.new("{}", Hash.new)
  #
  #   t = r.now
  #   assert_operator 1447873123, '<', t.to_i
  #
  #   ## redefine now for this instance.
  #   def r.now()
  #     return "10101"
  #   end
  #
  #   t = r.now
  #   assert_equal '10101', t.to_s, "override now method"
  # end
  #

end
