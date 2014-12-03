#require 'rubygems'

require_relative 'test_helper'

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
# require 'webmock/minitest'

require_relative '../WAPI_result_wrapper'
require 'logger'


class TestNew < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_instance_creation
    w = WAPIResultWrapper.new("A", "B", "C")
    z = WAPIResultWrapper.new("A", "B", "C")
    refute_nil(w, "create instance w")
    refute_nil(z, "create instance z")
    assert(z != w, "separate instances are different")
  end

  def test_values_retrieval
    w = WAPIResultWrapper.new("status", "msg", "result")

    assert_equal("status", w.meta_status, "got meta status")
    assert_equal("msg", w.meta_message, "got meta message")
    assert_equal("result", w.result, "got wrapped result")

  end

  def test_instance_values_kept_separate
    w = WAPIResultWrapper.new("status", "msg", "result")
    z = WAPIResultWrapper.new("HAPPY", "SAD", "HAPPY AGAIN")

    assert_equal("status", w.meta_status, "got meta status")
    assert_equal("msg", w.meta_message, "got meta message")
    assert_equal("result", w.result, "got wrapped result")

    assert_equal("HAPPY", z.meta_status, "got meta status")
    assert_equal("SAD", z.meta_message, "got meta message")
    assert_equal("HAPPY AGAIN", z.result, "got result")

  end

  def valid_json?(json)
    logger.info "#{__LINE__}: valid_json: json: "+json.inspect
    begin
      JSON.parse(json)
      return true
    rescue Exception => e
      return false
    end
  end

  def test_instance_full_value
    w = WAPIResultWrapper.new("status", "msg", "result")
    refute_nil(w, "create wrapped object")
    x = w.value_as_json
    refute_nil(x)
    assert valid_json?(x), "wrapped result should be json"

  end

end
