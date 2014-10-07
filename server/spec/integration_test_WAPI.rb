## Test WAPI module using real WSO2 API.

require 'Base64'
require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require '../WAPI'
require 'rest-client'
require 'logger'
require 'yaml'

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
    @prefix = application['prefix']
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
    @w = WAPI.new @prefix, @key, @secret, @token_server
  end

  # check that try to renew token if get a not-authorized response
  def test_token_invalid_and_is_renewed

    load_application 'SD-QA-BAD-TOKEN'
    w = WAPI.new @prefix, @key, @secret, @token_server
    assert_equal :ArmyBoots.to_s, @token.to_s

    ## use a request that will work but know token is bad
    r = @w.get_request("/Students/#{@uniqname}/Terms")
    assert_equal 200, r.code
  end

  def test_term_request
    r = @w.get_request("/Students/#{@uniqname}/Terms")
    j = JSON.parse(r)['getMyRegTermsResponse']
    assert_equal "2010", j['Term']['TermCode']
  end

  def test_course_request
    r = @w.get_request("/Students/#{@uniqname}/Terms/2010/Schedule")
    assert_equal 200, r.code
    r = JSON.parse(r)['getMyRegClassesResponse']['RegisteredClasses']
  end

end
