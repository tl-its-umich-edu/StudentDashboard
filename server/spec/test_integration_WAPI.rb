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
    log.level = Logger::DEBUG
    RestClient.log = log
  end

  def load_yml
    @@yml = YAML::load_file(File.open(@@yml_file))
  end

  def load_application(app_name)
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
     #   setup_logger
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
    assert_raises(URI::InvalidURIError) { r = w.get_request("/Students/#{@uniqname}/Terms") }
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
    assert_equal 200, r.code
  end

  def test_term_request
    r = @w.get_request("/Students/#{@uniqname}/Terms")
    j = JSON.parse(r)['getMyRegTermsResponse']['Term']
    assert_equal "2010", j['TermCode']
  end

  def test_term_request_bad_user
    skip("can not test without working ESB get 500 for unknown user")
    ## code below "works" for 500 / server error currently returned, but that response isn't appropriate
    assert_raises(RestClient::InternalServerError) { r = @w.get_request("/Students/FeelingGroovy/Terms")}
  end

  def test_course_request
    skip("can not test without working ESB")
    r = @w.get_request("/Students/#{@uniqname}/Terms/2010/Schedule")
    assert_equal 200, r.code
#    r = JSON.parse(r)['getMyRegClassesResponse']['RegisteredClasses']
    r = JSON.parse(r)['getMyClsScheduleResponse']['RegisteredClasses']
  end

end
