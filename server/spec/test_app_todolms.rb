ENV['RACK_ENV'] = 'test'

require 'rest-client'
require_relative '../courselist'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'rack/test'
require 'logger'

require_relative 'test_helper'

class AppTodolmsTest < Minitest::Test
  include Rack::Test::Methods
  include Logging

  # Test course list application
  def app
    # TODO: set logging level shouldn't be a class method.
    CourseList.setLoggingLevel "ERROR"
    CourseList.new
  end

  def parse_body_as_json body
    body_as_json = JSON.parse result
  end

  def test_settings
    get '/settings'
  end

  def test_todolms_generic

    get '/todolms'
    assert_equal 403, last_response.status, "don't respond to empty /todolms"

  end

  def test_todolms_user

    skip('must implement disk based provider')
    get '/todolms/bigbird.json'
    assert last_response.ok?, "get some result"

    body = last_response.body
    json = JSON.parse body
    refute_nil json,"get json for tolms user"
    result = json['Result'];

    # make sure we got some data we expected from canned data.
    assert_operator 19, "<=", result.length,"get todo data for bigbird"
    # some course needs to have this title.  Order of the values may be undefined.
    assert result.any? {|v|  (v['title'] =~ /Homework 2/) ? true : nil}, "find expected course"

  end

end
