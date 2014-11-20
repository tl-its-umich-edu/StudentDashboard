## Unit tests for WAPI module

require 'rubygems'

require 'simplecov'
SimpleCov.start

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require '../WAPI'
require 'rest-client'
require 'logger'
require 'base64'

# Standalone test for WAPI.  Uses webmock to allow running web requests without a real web server.
# See end of file for a bit more on webmock.

class TestNew < Minitest::Test

  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=Logger::ERROR
#    logger.level=Logger::DEBUG

    @token_server="http://tokenserver.micky.edu"
    @api_prefix = "PREFIX"

    a = Hash[
        'api_prefix' => @api_prefix,
        'token_server' => @token_server,
        'key' => 'A',
        'secret' => 'B',
        'token_server' => @token_server,
        'token' => 'sweet!'
    ]

    @w = WAPI.new(a)
  end

  def test_new_creates_something
    refute_nil @w
  end

  def test_format_url
    url = @w.format_url("/HOWDY")
    assert_equal "PREFIX/HOWDY", url
  end

  ## verify that base64 coding / decoding is working as expected
  def test_b64_working

    ### token test
    key = "0A3JhgnyQqmp0zTo1bEy1ZjqCG8aDFKJ"
    secret = "MdMZUgWdtyCIaaVC6qkY3143qysaMDMx"
    ks = key +":"+ secret

    a = "MEEzSmhnbnlRcW1wMHpUbzFiRXkxWmpxQ0c4YURGS0o6TWRNWlVnV2R0eUNJYWFWQzZxa1kzMTQzcXlzYU1ETXg="
    b = WAPI.base64_key_secret(key, secret)

    assert_equal a, b

    back_a = Base64.strict_decode64(a)
    back_b = Base64.strict_decode64(b)

    assert_equal back_a, back_b
  end

  ## Check the result wrapping method
  def test_wrapResultSimple
    r = WAPI.wrap_result(200, "OK", "good cheese")
    assert_equal(200, r["Meta"]["httpStatus"], "incorrect status")
    assert_equal("OK", r["Meta"]["Message"], "incorrect message")
    assert_equal("good cheese", r["Result"], "incorrect result")
  end

  #####################################


  # def test_get_request_successful
  #
  #   stub_request(:get, "https://api.edu/WSO2/Students/BitterDancer/Terms").
  #       with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer sweet!'}).
  #       to_return(:status => 200, :body => '{"mystuff":"yourstuff"}')
  #
  #   a = Hash['api_prefix' => "https://api.edu/WSO2",
  #            'key' => 'key',
  #            'secret' => 'secret',
  #            'token_server' => 'notoken',
  #            'token' => 'sweet!'
  #   ]
  #
  #   h = WAPI.new(a)
  #
  #   wr = h.get_request("/Students/BitterDancer/Terms")
  #   r = wr['Result']
  #   assert_equal 200, r.code
  # end

  def test_get_request_successful_query

    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer sweet!', 'User-Agent' => 'Ruby'}).
        to_return(:status => 200, :body => '{"mystuff":"yourstuff"}', :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]

    h = WAPI.new(a)
    wr = h.get_request("/hey")
    logger.info "#{__LINE__}: r "+wr.inspect

    ## get status of sucessful in wrapper
    assert_equal 200, wr['Meta']['httpStatus']

    r = wr['Result']
    logger.info "#{__LINE__}: r "+r.inspect
    ## get status of successful in actual response
    assert_equal 200, r.code

    ## verify that body came through
    body = JSON.parse(r.body)
    assert_equal "yourstuff", body["mystuff"]

  end

  #  Want to test token renewal on invalid token, but getting inconsistent webmock results.

  # check that try to renew token if get a not-authorized response
  # def test_token_invalid_and_is_renewed
  #
  #   stub_request(:get, "https://start/hey").
  #       with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Authorization' => 'Bearer sweet!'}).
  #       to_return(:status => 200, :body => "", :headers => {})
  #
  #   stub_request(:post, "http://key:secret@nowhere.edu/").
  #       with(:body => {"grant_type" => "client_credentials", "scope" => "PRODUCTION"},
  #            :headers => {'Accept' => '*/*; q=0.5, application/xml', 'Content-Length' => '46', 'Content-Type' => 'application/x-www-form-urlencoded'}).
  #       to_return(:status => 200, :body => "{}", :headers => {})
  #
  #   a = Hash['api_prefix' => "https://start",
  #            'key' => 'key',
  #            'secret' => 'secret',
  #            'token_server' => 'nowhere.edu',
  #            'token' => 'sweet!'
  #   ]
  #   h = WAPI.new(a);
  #   wr = h.get_request("/hey")
  #   logger.info "#{__LINE__}: wr: "+wr.inspect
  #   r = wr['Result']
  #   logger.info "#{__LINE__}: r: "+r.inspect
  #   assert_equal 200, r.code
  #
  # end

  # Make sure error result from query is wrapped and returned.
  def test_WAPI_do_request_unauthorized

    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Authorization' => 'Bearer sweet!'}).
        to_return(:status => 401, :body => "unauthorized", :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]
    h = WAPI.new(a);

    r = h.do_request("/hey")
    logger.info "tWdou: #{__LINE__}: r: "+r.inspect

    assert_equal(r['Meta']['httpStatus'], 666, "didn't get wrapped exception")

    exp = r['Result']
    assert_equal(exp.http_code, 401, "didn't catch unauthorized in do_request")

  end

  # Make sure error result from query is wrapped and returned.
  def test_WAPI_do_request_rest_client_error_417


    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Authorization' => 'Bearer sweet!'}).
        to_return(:status => 417, :body => "", :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]
    h = WAPI.new(a);

    r = h.do_request("/hey")

    assert_equal(r['Meta']['httpStatus'], 666, "didn't get wrapped exception")

  end

  ################ TODO: do do_request with successful request.

  # Make sure error result from query is wrapped and returned.
  def test_WAPI_do_request_successful

    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer sweet!', 'User-Agent' => 'Ruby'}).
        to_return(:status => 200, :body => '{"mystuff":"yourstuff"}', :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]
    h = WAPI.new(a);

    wr = h.do_request("/hey")
    logger.info "#{__LINE__}: wr "+wr.inspect
    #assert_equal(r['Meta']['httpStatus'], 200, "didn't get wrapped exception")

    ## get status of successful in wrapper
    assert_equal 200, wr['Meta']['httpStatus']

    r = wr['Result']
    logger.info "#{__LINE__}: r "+r.inspect
    ## get status of successful in actual response
    assert_equal 200, r.code

    ## verify that body came through
    body = JSON.parse(r.body)
    assert_equal "yourstuff", body["mystuff"]
  end


  # Make sure error result from query is wrapped and returned.
  def test_get_request_error_417

    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Authorization' => 'Bearer sweet!'}).
        to_return(:status => 417, :body => "", :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]
    h = WAPI.new(a);

    r = h.get_request("/hey")

    assert_equal(r['Meta']['httpStatus'], 666, "didn't get wrapped exception")
    exp = r['Result']
    assert_equal(exp.http_code, 417, "got incorrect wrapped exception")

  end


  def test_get_request_token_renewal_fails

    # add a singleton method to override internal method so can
    # ensure that the correct error is thrown without outside dependency.

    ###### mock methods that get_request will call
    ## make sure we get required exception
    def @w.do_request(a)
      WAPI.wrap_result(666, "MADEMEDOIT_request", nil)
    end

    # intercept the call to renew the token
    def @w.renew_token
      WAPI.wrap_result(666, "MADEMEDOIT_renew", nil)
    end

    wr = @w.get_request("howdy")
    assert(wr)
    logger.debug "#{__LINE__}: wr: "+wr.inspect
    #assert(s, "should have unauthorized wrapped result")
    #assert_equals("GROOVY", s, "lskd")

  end


  def test_get_request_uses_do_request_successful

    # add a singleton method to override internal method so can
    # ensure that the desired result is returned
    # http://ruby-doc.org/stdlib-1.9.3/libdoc/minitest/mock/rdoc/MiniTest/Mock.html

    def @w.do_request(a)
      mock = MiniTest::Mock.new()
      mock.expect(:code, 999)
      mock.expect(:code, 999)
      WAPI.wrap_result(999, "MADEMEDOIT", mock)

      #return WAPI.wrap_result("200","wrapped mock return value",mock)
    end

    wr = @w.get_request("howdy")
    logger.info "#{__LINE__}: wr: "+wr.inspect
    r = wr['Result']
    logger.info "#{__LINE__}: r: "+r.inspect
    assert_equal(999, r.code, "did not get response mock back")
    r.verify

  end

  def test_renew_token_successful

    stub_request(:post, "http://key:secret@nowhere.edu/").
        with(:body => {"grant_type" => "client_credentials", "scope" => "PRODUCTION"},
             :headers => {'Accept' => '*/*; q=0.5, application/xml', 'Content-Length' => '46', 'Content-Type' => 'application/x-www-form-urlencoded'}).
        to_return(:status => 200, :body => '{"token_type":"bearer","expires_in":3600,"access_token":"HAPPY_FEET"}', :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]
    h = WAPI.new(a);

    r = h.renew_token
    logger.info "#{__LINE__}: r: "+r.inspect
    assert_equal(r['Meta']['httpStatus'], 200, "didn't get token renewal")
    exp = JSON.parse(r['Result'])
    logger.info "#{__LINE__}: exp: "+exp.inspect

    assert_equal(exp['access_token'], "HAPPY_FEET", "got incorrect wrapped body")

  end

  def test_renew_token_fail

    stub_request(:post, "http://key:secret@nowhere.edu/").
        with(:body => {"grant_type" => "client_credentials", "scope" => "PRODUCTION"},
             :headers => {'Accept' => '*/*; q=0.5, application/xml', 'Content-Length' => '46', 'Content-Type' => 'application/x-www-form-urlencoded'}).
        to_return(:status => 401, :body => '', :headers => {})

    a = Hash['api_prefix' => "https://start",
             'key' => 'key',
             'secret' => 'secret',
             'token_server' => 'nowhere.edu',
             'token' => 'sweet!'
    ]

    h = WAPI.new(a);

    r = h.renew_token
    logger.info "#{__LINE__}: r: "+r.inspect
    assert_equal(401, r['Meta']['httpStatus'], "token should not renew")

  end

end
