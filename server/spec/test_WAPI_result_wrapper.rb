require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'

require_relative '../WAPI_result_wrapper'
require 'logger'
require_relative '../Logging'
require_relative 'test_helper'

class TestWAPIResultWrapper < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    logger.level=TestHelper.getCommonLogLevel
    #logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_instance_creation_default_more
    w = WAPIResultWrapper.new("A", "B", "C")
    z = WAPIResultWrapper.new("A", "B", "C")
    refute_nil(w, "create instance w")
    refute_nil(z, "create instance z")
    assert(z != w, "separate instances are different")
  end

  def test_instance_creation_default_explict_more
    w = WAPIResultWrapper.new("A", "B", "C", "D")
    z = WAPIResultWrapper.new("A", "B", "C", "D")
    refute_nil(w, "create instance w")
    refute_nil(z, "create instance z")
    assert(z != w, "separate instances are different")
  end

  def test_values_retrieval
    w = WAPIResultWrapper.new("status", "msg", "result", "more")

    assert_equal("status", w.meta_status, "get meta status")
    assert_equal("msg", w.meta_message, "get meta message")
    assert_equal("more", w.meta_more, "get meta more")
    assert_equal("result", w.result, "get wrapped result")

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
    w = WAPIResultWrapper.new("status", "msg", "result", "more")
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

  def test_update_more
    w = WAPIResultWrapper.new("status", "msg", "result", "MORE")
    assert_equal(w.meta_more, "MORE", "get value of more")
    w.meta_more_update("NEW_MORE")
    assert_equal('NEW_MORE', w.meta_more, "get new value of more")
  end

  def test_append_wrappers
    w = WAPIResultWrapper.new("status", "msg", '["resultA"]', "moreA")
    x = WAPIResultWrapper.new("status B", "msg B", '["resultB"]')

    y = w.append_json_results(x)
    assert_equal('["resultA","resultB"]', y.result, "concatenate results")
    assert_equal(0, y.meta_more.length, "more url is empty")

  end

  def test_append_wrappers_with_additional_link
    w = WAPIResultWrapper.new("status", "msg", '["resultA"]', "moreA")
    x = WAPIResultWrapper.new("status B", "msg B", '["resultB"]', "moreB")

    y = w.append_json_results(x)
    assert_equal('["resultA","resultB"]', y.result, "concatenate results")
    assert_equal("moreB", y.meta_more, "more url is from second wrapper")

  end
end
