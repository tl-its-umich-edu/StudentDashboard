## Unit tests for WAPI module

require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require '../WAPI'
require 'rest-client'
require 'Base64'

# Standalone test for WAPI.  Uses webmock to allow running web requests without a real web server.
# See end of file for a bit more on webmock.

class TestNew < Minitest::Test

  def setup
    @token_server="http://tokenserver.micky.edu"
    @prefix = "PREFIX"
    @w = WAPI.new @prefix, "A", "B", @token_server
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

  def test_url_terms_query

    stub_request(:get, "https://api.edu/WSO2/Students/BitterDancer/Terms").
        with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer sweet!'}).
        to_return(:status => 200, :body => '{"mystuff":"yourstuff"}')

    h = WAPI.new("https://api.edu/WSO2", "key", "secret", "notoken", "sweet!")

    r = h.get_request("/Students/BitterDancer/Terms")
    assert_equal 200, r.code
  end

  def test_run_request_sample_query

    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer Toker', 'User-Agent' => 'Ruby'}).
        to_return(:status => 200, :body => '{"mystuff":"yourstuff"}', :headers => {})

    h = WAPI.new("https://start", "key", "secret", "nowhere.edu");
    r = h.get_request("/hey")
    rb = JSON.parse(r.body)
    #puts r
    assert_equal "yourstuff", rb["mystuff"]

  end

  #  Want to test token renewal on invalid token, but getting inconsistent webmock results.

  # check that try to renew token if get a not-authorized response
  def test_token_invalid_and_is_renewed
    skip("inconsistent test results")
    #stub_request(:get, "https://start/hey").
     #  with(:headers => {'Accept' => 'application/json', 'Authorization' => 'Bearer Toker', 'User-Agent' => 'Ruby'}).
     #   to_return(:status => 401, :body => '{"mystuff":"yourstuff"}', :headers => {})

    stub_request(:get, "https://start/hey").
        with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Authorization'=>'Bearer', 'User-Agent'=>'Ruby', 'Verify-Ssl'=>'true'}).
        to_return(:status => 200, :body => "", :headers => {})

    stub_request(:post, "http://key:secret@nowhere.edu/").
        with(:body => {"grant_type"=>"client_credentials", "scope"=>"PRODUCTION"},
             :headers => {'Accept'=>'*/*; q=0.5, application/xml',  'Content-Length'=>'46', 'Content-Type'=>'application/x-www-form-urlencoded'}).
        to_return(:status => 200, :body => "{}", :headers => {})

    h = WAPI.new("https://start", "key", "secret", "nowhere.edu");
    r = h.get_request("/hey")

    assert_equal 200, r.code

  end

  ### sample webmock test
  ### If webmock check fails it will print out the stub_request that would have passed so you can
  ### see what went wrong.
=begin
  def test_rc ()
    stub_request(:post, "www.example.com").
        with(:body => {:data => {:a => '1', :b => 'five'}})

    RestClient.post('www.example.com', "data[a]=1&data[b]=five",
                    :content_type => 'application/x-www-form-urlencoded') # ===> Success

    RestClient.post('www.example.com', '{"data":{"a":"1","b":"five"}}',
                    :content_type => 'application/json') # ===> Success

    RestClient.post('www.example.com', '<data a="1" b="five" />',
                    :content_type => 'application/xml') # ===> Success

  end
=end

end
