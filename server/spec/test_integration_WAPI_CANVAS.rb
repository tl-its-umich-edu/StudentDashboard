## Test WAPI module using real WSO2 API.

require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require_relative '../WAPI'
require_relative '../data_provider_esb'
require_relative '../courselist'

require 'rest-client'
require 'logger'
require 'yaml'
require 'base64'
require 'json'

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
  def run_and_get_ruby_result(url)
    r = @w.get_request url
    result = r.result
    result_as_ruby = JSON.parse result
    result_as_ruby
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
    result_as_json = run_and_get_ruby_result(request_url)
    assert_equal "api-esb-poweruser", result_as_json['sis_login_id'], "found tl poweruser"
  end

  ## test for explicit self profile request
  def test_canvas_api_self_profile
    refute_nil @w
    request_url = "/users/self/profile"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_equal "api-esb-poweruser", result_as_json['sis_login_id'], "found tl poweruser"
  end

  ## test for data about another user.
  def test_canvas_api_gsilver_profile
    refute_nil @w
    request_url = "/users/sis_login_id:gsilver/profile"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_equal "gsilver", result_as_json['sis_login_id'], "find tl gsilver"
  end

  ## test for course data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_courses
    refute_nil @w
    request_url = "/courses?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some classes back"
  end

  ## test for activity_stream data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_activity_stream
    refute_nil @w
    request_url = "/users/activity_stream?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some activities back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_self_activity_stream
    refute_nil @w
    ## this works with or without self in url
    request_url = "/users/self/activity_stream?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some activities back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_activity_stream_summary
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/activity_stream/summary?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some activities back"
  end

  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_self_upcoming_events
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/upcoming_events?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end

  #   curl -G -H "Authorization: Bearer $TOKEN" \
  # -v --dump-header $$.header \
  # "https://umich.test.instructure.com/api/v1/users/346909/calendar_events" \
  # --data-urlencode "type=assignment" \
  # --data-urlencode "start_date=2016-01-01" \
  # --data-urlencode "context_codes[]=course_43412" \

  # --data-urlencode "context_codes[]=course_44630"

  def test_process_url_params_idempotent
    # verify that using url method from RestClient doesn't change existing url
    request_url="/users/self/upcoming_events?as_user_id=sis_login_id:studenta"
    full_request_url = RestClient::Request.new(:method => :get, :url => request_url).url
    #puts "full_request_url: [#{full_request_url}]"
    refute_nil full_request_url
    assert_equal(request_url, full_request_url)
  end

  def test_process_url_params_separate
    # verify that adding parameters via RestClient params header works as expected and escapes characters.
    request_url="/users/self/upcoming_events"
    request_parameters = {:as_user_id => 'sis_login_id:studenta', :furballs => 'tom&jerry&bob'}
    full_request_url = RestClient::Request.new(:method => :get, :url => request_url, :headers => {:params => request_parameters}).url
    refute_nil full_request_url
    assert_equal '/users/self/upcoming_events?as_user_id=sis_login_id%3Astudenta&furballs=tom%26jerry%26bob', full_request_url
  end

  ## test for assignment data about a (test) student.  This uses masquerade.
  ## Test using RestClient to add parameters to url
  def test_canvas_api_studenta_upcoming_events_headers
    refute_nil @w
    ## this requires self in url
    #request_url = "/users/self/upcoming_events?as_user_id=sis_login_id:studenta"
    request_url = "/users/self/upcoming_events"
    request_parameters = {:params => {:as_user_id => 'sis_login_id:studenta'}}
    full_request_url = RestClient::Request.new(:method => :get, :url => request_url, :headers => request_parameters).url
    #full_request_url.gsub!(/%3A/, ':')

   # puts "full_request_url: #{full_request_url}"
    result_as_json = run_and_get_ruby_result(full_request_url)
    #puts "result: "+result_as_json.inspect
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end


  def test_canvas_api_todo

    user='nabuzoor'
    request_url = "/users/self/todo"
    per_page = nil
    start_date = nil
    #per_page = 100
    #start_date = '2016-01-01'

    correct = "/users/self/calendar_events?as_user_id=sis_login_id:ralt&type=assignment&start_date=2016-01-01&per_page=100&context_codes[]=course_48961&context_codes[]=course_52008&context_codes[]=course_52010"
    correct_array = correct.split(/&/).sort()

    param = {
        :as_user_id => "sis_login_id:#{user}",
    }

    if !per_page.nil? && per_page > 0
      param[:per_page] = per_page
    end

    if !start_date.nil?
      param[:start_date] = start_date
    end

    request_parameters = {:params => param}

    string_request_url = RestClient::Request.new(:method => :get, :url => request_url, :headers => request_parameters).url
    #string_request_url << CourseList.course_list_string([48961, 52008, 52010])
    string_request_url.gsub!(/%3A/, ':')

    #assert_equal(correct.split(/&/).sort(), string_request_url.split(/&/).sort(), "query has correct entries")

    ### sample of current link url.
    #https://api-qa-gw.its.umich.edu/api/v1/users/self/calendar_events?as_user_id=sis_login_id%3Aralt&context_codes%5B%5D=course_48961&context_codes%5B%5D=course_52008&context_codes%5B%5D=course_52010&start_date=2016-01-01&type=assignment&page=1&per_page=10

    #puts "string_request_url: #{string_request_url.inspect}"
    result = run_and_get_ruby_result(string_request_url)
    #puts "result_as_json: #{result.to_json}"

    skip("experimenting with todo")
  end

  # URL="$BASE/v1/users/self/calendar_events?as_user_id=sis_login_id:$USER" # as_user_id
  #
  # curl -G -H "Authorization: Bearer $TOKEN" \
  #    -v --dump-header $$.header \
  #    $URL \
  #    --data-urlencode "type=assignment" \
  #    --data-urlencode "start_date=2016-01-01" \
  #    --data-urlencode "context_codes[]=course_48961" \
  #    --data-urlencode "context_codes[]=course_52008" \
  #    --data-urlencode "context_codes[]=course_52010" \
  #    --data-urlencode "per_page=100" \


  def test_canvas_api_calendar_events_class_per_page

    user='ralt'
    request_url = "/users/self/calendar_events"
    per_page = nil
    start_date = nil
    per_page = 100
    start_date = '2016-01-01'

    correct = "/users/self/calendar_events?as_user_id=sis_login_id:ralt&type=assignment&start_date=2016-01-01&per_page=100&context_codes[]=course_48961&context_codes[]=course_52008&context_codes[]=course_52010"
    correct_array = correct.split(/&/).sort()

    param = {
        :as_user_id => "sis_login_id:#{user}",
        :type => "assignment",
    }

    if !per_page.nil? && per_page > 0
      param[:per_page] = per_page
    end

    if !start_date.nil?
      param[:start_date] = start_date
    end

    request_parameters = {:params => param}

    string_request_url = RestClient::Request.new(:method => :get, :url => request_url, :headers => request_parameters).url
    string_request_url << CourseList.course_list_string([48961, 52008, 52010])
    string_request_url.gsub!(/%3A/, ':')

    assert_equal(correct.split(/&/).sort(), string_request_url.split(/&/).sort(), "query has correct entries")

    ### sample of current link url.
    #https://api-qa-gw.its.umich.edu/api/v1/users/self/calendar_events?as_user_id=sis_login_id%3Aralt&context_codes%5B%5D=course_48961&context_codes%5B%5D=course_52008&context_codes%5B%5D=course_52010&start_date=2016-01-01&type=assignment&page=1&per_page=10

    #puts "string_request_url: #{string_request_url.inspect}"
    result = run_and_get_ruby_result(string_request_url)
    #puts "result: #{result.inspect}"

    skip("Not sure about quoting in string as yet")
  end

  #RestClient will effectively overwrite parameters with the same name

  # fake list of canvas courses (for nabuzoor)
  #"canvas_courses"=>["43412", "44525", "44526", "44631", "44630", "44528", "44530"]}

  def test_canvas_api_studenta_calendar_events_headers

    ### want to construct full text url since not currently passing in separate parameters and
    ### it can't handle the context_code parameters anyway.

    ## build url via using RestClient utility to add/escape query parameters that don't repeat.
    ## add repeating query parameters via own code.

    refute_nil @w

    user='dlhaines'

    request_url = "/users/self/calendar_events"
    request_parameters = {:params => {:as_user_id => "sis_login_id:#{user}",
                                      :type => 'assignment',
                                      :start_date => '2016-01-01'
    }}

    # Generate url with query parameters.
    string_request_url = RestClient::Request.new(:method => :get, :url => request_url, :headers => request_parameters).url
    #### test to see if need to unescape :
    string_request_url.gsub!(/%3A/, ':')
    #puts string_request_url.inspect
    full_request_url = string_request_url

    ### add repeating query parameters.  This is specific to course list
    full_request_url << CourseList.course_list_string([43412, 44630])
    #puts full_request_url.inspect
    result_as_json = run_and_get_ruby_result(full_request_url)
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end

  # # assemble context codes to specify the set of courses.  Explicit method is required since RestClient
  # # doesn't correctly deal with multiple parameters with same name as yet.
  # ## could generalize this to pass in prefix.
  # def course_list_string(courses)
  #   courses.inject("") { |result, course| result << "&context_codes[]=course_#{course}" }
  # end
  #
  # def test_assemble_course_parameters
  #   course_ids = [43412, 44630]
  #   correct="&context_codes[]=course_43412&context_codes[]=course_44630"
  #   #encoded = course_list_string ['43412','44630']
  #   encoded = course_list_string [43412, 44630]
  #   assert_equal correct, encoded, "multiple courses as parameters"
  # end


  ## test for assignment data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_calendar_events
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/upcoming_events?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end


  ## test for data about a (test) student.  This uses masquerade.
  def test_canvas_api_studenta_self_todo
    refute_nil @w
    ## this requires self in url
    request_url = "/users/self/todo?as_user_id=sis_login_id:studenta"
    result_as_json = run_and_get_ruby_result(request_url)
    assert_operator result_as_json.length, ">=", 1, "got some upcoming events back"
  end

end
