## Test WAPI module using real WSO2 API.


require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require '../WAPI'
require 'rest-client'
require 'logger'
require 'yaml'
require 'base64'


### Test WAPI with real server

class TestNew < Minitest::Test

  ## security.yml holds security configuration information for testing.
  ## See security.yml.TEMPLATE for details.
  ## Configurations are grouped by an arbitrary Application name and can
  ## be loaded separately.

  @@yml_file = "./security.yml"
  @@application = "test"
  @@yml = nil
  @@config = nil

  def setup_logger
    log = Logger.new(STDOUT)
#    log.level = Logger::ERROR
#log.level = Logger::DEBUG
    RestClient.log = log
  end

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
  end

  def setup
    # by default assume that the tests will run well and don't
    # need detailed log messages.
    logger.level=Logger::ERROR
#    logger.level=Logger::DEBUG

    load_yml
    load_application 'SD-QA'

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

    load_application 'SD-QA-BAD-TOKEN'

    a = Hash['api_prefix' => "https://nowhere_nothing_nada.com",
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             'token' => @token
    ]

    w = WAPI.new(a)

    # check that unknown errors are passed on.
    #assert_raises(URI::InvalidURIError) { r = w.get_request("/Students/#{@uniqname}/Terms")
    r = w.get_request("/Students/#{@uniqname}/Terms.XXX")
    logger.debug "#{__LINE__}: toepo: r "+r.inspect
    assert_equal 666, r['Meta']['httpStatus'], "missed capturing exception"
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
    logger.info "#{__LINE__}: ttiair: r "+r.inspect
    httpStatus = r['Meta']['httpStatus']
    assert_equal 200, httpStatus
  end

  def test_term_request
    r = @w.get_request("/Students/#{@uniqname}/Terms")
    logger.info "#{__LINE__}: ttr: r "+r.inspect
    res = r['Result']
    #logger.debug "#{__LINE__}: tcr: res: "+res.inspect
    ## note result is returned verbatim so likely needs to be parsed.
    res = JSON.parse(res)
    j = res['getMyRegTermsResponse']['Term']
    assert j.length > 0, "need at least 1 term"
  end

  def test_term_request_bad_user
    logger.info 'test_term_request_bad_user'
#    skip("can not test without working ESB get 500 for unknown user")
## code below "works" for 500 / server error currently returned, but that response isn't appropriate
#    assert_raises(RestClient::InternalServerError) { r = @w.get_request("/Students/FeelingGroovy/Terms")}

    r = @w.get_request("/Students/FeelingGroovy/Terms")

  end

  def test_course_request

    default_term = 2010
    r = @w.get_request("/Students/#{@uniqname}/Terms/#{default_term}/Schedule")
    logger.info "#{__LINE__}: tcr: r "+r.inspect

    # check status
    httpStatus = r['Meta']['httpStatus']
    #    logger.info "#{__LINE__}: tcr: httpStatus #{httpStatus}"
    assert_equal 200, httpStatus, "unexpected response code"

    # check value
    res = r['Result']
    #logger.debug "#{__LINE__}: tcr: res: "+res.inspect
    ## note result is returned verbatim so likely needs to be parsed.
    res = JSON.parse(res)
    #logger.debug "#{__LINE__}: tcr: parse res: "+res.inspect
    cls = res['getMyClsScheduleResponse']['RegisteredClasses']
    #logger.debug "#{__LINE__}: tcr: cls: "+cls.inspect

    refute_nil(cls[0], "There should be at least one class")
    refute_nil(cls[0]['Title'], "That class should have a title")

  end

end
