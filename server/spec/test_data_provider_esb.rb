## Unit tests for provider esb module

require_relative 'test_helper'

require 'rubygems'

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require_relative '../data_provider_esb'
require 'logger'
require_relative '../../server/Logging'
require_relative '../WAPI'


# Test parsing of potential results from ESB.  Tests concentrate
# on parsing the JSON.

class TestProviderESB < MiniTest::Test
  include Logging

  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG

    # create class to test module
    @m = Class.new do
      include DataProviderESB
      include Logging
    end.new
  end

  def test_new_creates_something
    refute_nil @m
  end

  def test_esb_terms_null
    # fix null entry
    h = '{"getMyRegTermsResponse":null}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::SUCCESS, t.meta_status, 'ESB returned value was null, we make it empty array')
    assert_equal(0,t.result.length,"empty array")
  end

  def test_esb_terms_nil
    # this is an error because it isn't valid json
    h = '{"getMyRegTermsResponse":nil}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::UNKNOWN_ERROR, t.meta_status, 'ESB returned value was nil, which is not valid json')
  end

  def test_esb_terms_empty_string
    # make empty string into empty array
    h = '{"getMyRegTermsResponse":""}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::SUCCESS, t.meta_status, 'ESB returned value was empty string, we make it empty array')
    assert_equal(0,t.result.length,"empty array")
  end

  def test_esb_parse_terms_good
    # make sure valid term is ok
    h = '{"getMyRegTermsResponse":{"Term":[{"TermCode":"2020","TermDescr":"Winter 2015","TermShortDescr":"WN 2015"}]}}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::SUCCESS, t.meta_status, 'ESB returned value was good')
  end
end
