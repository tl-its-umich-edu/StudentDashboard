#require 'rubygems'

require_relative 'test_helper'

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
# require 'webmock/minitest'

require_relative '../WAPI_result_wrapper'
require 'logger'


class TestWAPIResultWrapper < Minitest::Test

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

  def test_value_of_nil
    # if get back nil terms still have it parse ok.
    w = WAPIResultWrapper.new("status", "msg", Hash.new['getMyRegTermsResponse']=nil)
    refute_nil(w, "create wrapped object")
    assert w.valid?, "check for valid wrapper object"
    t = JSON.parse(w.value_as_json)['Result']
    assert_equal(t, "", "get back empty string")
  end

  def test_value_is_empty_string
    # if get back empty string as terms still have it parse ok.
    w = WAPIResultWrapper.new("status", "msg", Hash.new['getMyRegTermsResponse']="")
    refute_nil(w, "create wrapped object")
    assert w.valid?, "check for valid wrapper object"
    t = JSON.parse(w.value_as_json)['Result']
    assert_equal(t, "", "get back empty string")
  end

  def test_valid_wrapper
    w = WAPIResultWrapper.new("status", "msg", "result")
    refute_nil(w, "create wrapped object")
    assert w.valid?, "check for valid wrapper object"
  end

  def test_invalid_wrapper
    w = WAPIResultWrapper.new("status", "msg", "result")
    w.setValue(Hash["micro", "true"])
    refute w.valid?, "check for valid wrapper object"
  end

end
