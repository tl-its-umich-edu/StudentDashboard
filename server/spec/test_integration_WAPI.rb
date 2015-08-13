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

#require 'logger'
include Logging

### Test WAPI with real server

class TestIntegrationWAPI < Minitest::Test

  ## security.yml holds security configuration information for testing.
  ## See security.yml.TEMPLATE for details.
  ## Configurations are grouped by an arbitrary Application name and can
  ## be loaded separately.

  @@yml_file = TestHelper.findSecurityFile "security.yml"
  @@application = "SD-QA"

  @@yml = nil
  @@config = nil

  def load_yml
    @@yml = YAML::load_file(File.open(@@yml_file))
  end

  def load_application(app_name)

    logger.debug "#{__LINE__}: la: application: #{app_name}"
    application = @@yml[app_name]
    @token_server = application['token_server']
    @api_prefix = application['api_prefix']
    @key = application['key']
    @secret = application['secret']
    @token = application['token']
    ## special uniqname is supplied for testing
    @uniqname = application['uniqname']
    @default_term = application['default_term']
  end

  def setup
    # by default assume that the tests will run well and don't
    # need detailed log messages.

    logger.level=TestHelper.getCommonLogLevel
    #logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG

    @default_application_name = 'SD-QA'
    load_yml
    #load_application 'ESB-QA'
    #load_application 'SD-TEST-DLH'
    load_application @default_application_name

    @default_term = '2020';

    a = Hash['api_prefix' => @api_prefix,
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             'token' => 'sweet!'
    ]

    @w = WAPI.new(a)
  end

  # check that bad host gets caught.
  def test_outside_exception_passed_on

    #load_application 'SD-QA-BAD-TOKEN'
    #load_application 'ESB-QA'
    #load_application 'SD-QA'
    load_application @default_application_name

    a = Hash['api_prefix' => "https://nowhere_nothing_nada.com",
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             'token' => @token
    ]

    w = WAPI.new(a)

    # check that unknown errors are passed on.
    r = w.get_request("/Students/#{@uniqname}/Terms.XXX")
    logger.debug "#{__LINE__}: toepo: r "+r.inspect
    assert_equal 400, r.meta_status, "missed capturing exception: status returned: #{r.meta_status}"

  end

  # check that try to renew token if get a not-authorized response
  def test_token_invalid_and_is_renewed

    load_application 'SD-QA-BAD-TOKEN'

    a = Hash['api_prefix' => @api_prefix,
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             'token' => @token
    ]

    w = WAPI.new(a)
    assert_equal :ArmyBoots.to_s, @token.to_s

    ## use a request that will work but know token is bad
    r = w.get_request("/Students/#{@uniqname}/Terms")
    #r = r.response
    logger.info "#{__LINE__}: ttiair: r "+r.inspect
    httpStatus = r.meta_status
    assert_equal 200, httpStatus
  end

  def test_term_request
    r = @w.get_request("/Students/#{@uniqname}/Terms")
    logger.info "#{__LINE__}: ttr: r "+r.inspect
    res = r.result
    ## note result is returned verbatim so likely needs to be parsed.
    logger.debug "#{__LINE__}: ttr: j "+j.inspect
    j = res['getMyRegTermsResponse']['Term']
    assert j.length > 0, "need at least 1 term"
  end

  def test_term_request_unknown_user
    #skip "does not work with stubs"
    logger.info 'test_term_request_unknown_user'

    r = @w.get_request("/Students/FeelingGroovy/Terms")
# check status
    httpStatus = r.meta_status
    assert_equal 404, httpStatus, "unexpected response code"

  end

  def test_course_request

    @default_term = 2060
    r = @w.get_request("/Students/#{@uniqname}/Terms/#{@default_term}/Schedule")
    logger.info "#{__LINE__}: tcr: r "+r.inspect

    # check status
    httpStatus = r.meta_status
    assert_equal 200, httpStatus, "unexpected response code"

    # check value
    res = r.result
    ## note result is returned verbatim so likely needs to be parsed.
    res = JSON.parse(res)

    cls = res['getMyClsScheduleResponse']['RegisteredClasses']

    refute_nil(cls[0], "There should be at least one class")
    refute_nil(cls[0]['Title'], "That class should have a title")

  end

end
