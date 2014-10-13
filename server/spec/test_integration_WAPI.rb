## Test WAPI module using real WSO2 API.


require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require '../WAPI'
require 'rest-client'
require 'logger'
require 'yaml'
require 'Base64'


### Test WAPI with real server

class TestNew < Minitest::Test

  ## security.yaml holds security configuration information for testing.
  ## See security.yaml.TEMPLATE for details.
  ## Configurations are grouped by an arbitrary Application name and can
  ## be loaded separately.

  @@yaml_file = "./security.yaml"
  @@application = "test"
  @@yaml = nil
  @@config = nil

  def setup_logger
    log = Logger.new(STDOUT)
    log.level = Logger::DEBUG
    RestClient.log = log
  end

  def load_yaml
    @@yaml = YAML::load_file(File.open(@@yaml_file))
  end

  def load_application(app_name)
    application = @@yaml[app_name]
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
     load_yaml
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
    skip("get 500 for unknown user")
    r = @w.get_request("/Students/FeelingGroovy/Terms")
  end

  def test_course_request
    r = @w.get_request("/Students/#{@uniqname}/Terms/2010/Schedule")
    assert_equal 200, r.code
    r = JSON.parse(r)['getMyRegClassesResponse']['RegisteredClasses']
  end

end
