## Test WAPI module using real WSO2 API.

require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require_relative '../WAPI'
require_relative '../data_provider_esb'
require 'rest-client'
require 'logger'
require 'yaml'
require 'base64'

require_relative 'test_helper'

# To print details during the test run uncomment the TRACE=1 line
TRACE=FalseClass
#TRACE=1

include Logging

### Test WAPI use with Canvas

class TestIntegrationWAPICANVAS < Minitest::Test

  ## security.yml holds security configuration information for testing.
  ## See security.yml.TEMPLATE for details.
  ## Configurations are grouped by an arbitrary Application name and can
  ## be loaded separately.

  @@yml_file = TestHelper.findSecurityFile("security.yml")
  logger.debug "yml_file: #{@@yml_file}"
  @@yml = nil
  @@config = nil

  def load_yml
    @@yml = YAML::load_file(File.open(@@yml_file))
  end

  def load_application(app_name)

    logger.debug "#{__LINE__}: la: app_name: #{app_name}"

    application = @@yml[app_name]
    logger.debug "#{__LINE__}: la: application.inspect: #{application.inspect}"
    @token_server = application['token_server']
    @api_prefix = application['api_prefix']
    @key = application['key']
    @secret = application['secret']
    @token = application['token']
    ## special uniqname is supplied for testing
    @uniqname = application['uniqname']
    #logger.debug "#{__LINE__}: la: token: #{@token} key: #{@key} secret: #{@secret}"
  end

  def setup
    # by default assume that the tests will run well and don't
    # need detailed log messages.

    logger.level=TestHelper.getCommonLogLevel
    #logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG

    #@default_application_name = 'SD-QA-CANVAS'
    #@default_application_name = 'Canvas-TL-TEST'
    @default_application_name = 'CANVAS-TL-QA'
    #@default_application_name = 'CANVAS-ADMIN-DEV'
    load_yml
    load_application @default_application_name

    @default_term = '2060';

    a = Hash['api_prefix' => @api_prefix,
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             #'token' => '!sweet',
             'token' => @token
    ]

    @w = WAPI.new(a)
  end


  ## run a request and parse result as json.  This assumes that request will work
  ## and the result is valid json.
  def run_and_get_json_result(url)
    r = @w.get_request url
    result = r.result
    result_as_json = JSON.parse result
    puts "url: #{url} result: "+result_as_json.inspect unless TRACE == FalseClass
    result_as_json
  end

  ############## tests

  # check that api object exists.
  def test_canvas_api_object_exists
    refute_nil @w
  end


  #### These test capabilities of tl esb poweruser API.

  ## get expected data for self request
  def test_canvas_api_self
    refute_nil @w
    request_url = "/users/self"
    result_as_json = run_and_get_json_result(request_url)
    assert_equal "api-esb-poweruser", result_as_json['sis_login_id'], "found tl poweruser"
  end

  ## test for explicit self profile request
  def test_canvas_api_self_profile
    refute_nil @w
    request_url = "/users/self/profile"
    result_as_json = run_and_get_json_result(request_url)
    assert_equal "api-esb-poweruser", result_as_json['sis_login_id'], "found tl poweruser"
  end

  ## test for data about another user.
  def test_canvas_api_gsilver_profile
    refute_nil @w
    request_url = "/users/sis_login_id:gsilver/profile"
    result_as_json = run_and_get_json_result(request_url)
    assert_equal "gsilver", result_as_json['sis_login_id'], "find tl gsilver"
  end

  ## test for course data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_courses
    refute_nil @w
    request_url = "/courses?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_json_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some classes back"
  end

  ## test for activity_stream data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_activity_stream
    refute_nil @w
    request_url = "/users/activity_stream?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_json_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some activities back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_self_activity_stream
    refute_nil @w
    ## this works with or without self in url
    request_url = "/users/self/activity_stream?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_json_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some activities back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_activity_stream_summary
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/activity_stream/summary?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_json_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some activities back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_self_upcoming_events
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/upcoming_events?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_json_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_self_todo
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/todo?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_json_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end

end
