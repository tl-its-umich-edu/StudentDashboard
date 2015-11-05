## Unit tests for canvas esb module

require 'rubygems'

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require_relative '../data_provider_esb'
require 'logger'
require_relative '../../server/Logging'
require_relative '../data_provider_canvas_esb'
require_relative '../WAPI'

require_relative '../Logging'

require_relative 'test_helper'
# Test parsing of potential results from ESB.  Tests concentrate
# on parsing the JSON.

class TestDataProviderCanvasESB < MiniTest::Test
  include Logging

  def load_yml
    @@yml = YAML::load_file(File.open(@@yml_file))
  end

  def load_application(app_name)

    logger.debug "#{__LINE__}: la: app_name: #{app_name}"

    application = @@yml[app_name]
    logger.debug "#{__LINE__}: la: application.inspect: #{application.inspect}"
    @token_server = application['token_server']
    @api_prefix = application['api_prefix']
    @key = application['key']
    @secret = application['secret']
    @token = application['token']
    ## special uniqname is supplied for testing
    #logger.debug "#{__LINE__}: la: token: #{@token} key: #{@key} secret: #{@secret}"
  end

  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=TestHelper.getCommonLogLevel
    #logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG

    @@yml_file = TestHelper.findSecurityFile("security.yml")
    logger.debug "yml_file: #{@@yml_file}"
    @@yml = nil
    @@config = nil

    #@default_application_name = 'SD-QA-CANVAS'
    #@default_application_name = 'Canvas-TL-TEST'
    @default_application_name = 'CANVAS-TL-QA'
    #@default_application_name = 'CANVAS-ADMIN-DEV'
    load_yml
    load_application @default_application_name

    @default_term = '2060';

    a = Hash['api_prefix' => @api_prefix,
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             #'token' => '!sweet',
             'token' => @token
    ]

    @w = WAPI.new(a)

    # create class to test module
    @m = Class.new do
      include DataProviderCanvasESB
      include Logging
    end.new
  end

  def test_new_creates_something
    refute_nil @m
  end

  # Assuming that studenta is kept up to date with some upcoming events
  def test_upcoming_events_studenta
    r = @w.get_request "/users/self/upcoming_events?as_user_id=sis_login_id:studenta"
    result_as_string = r.result
    logger.debug "test_upcoming_events_studenta: result: "+result_as_string
    result_as_ruby = JSON.parse result_as_string
    #logger.debug "test_upcoming_events_studenta: "+result_as_json.inspect
    logger.debug "test_upcoming_events_studenta: result_as_ruby: "+result_as_ruby.inspect

    assert_equal(9, result_as_ruby.length, "find some upcoming events")

    id_0 = result_as_ruby[0]['id']
    refute_nil id_0, "have id"
    assert_operator id_0, '>', 0, "id is positive"

    title_0 = result_as_ruby[0]['title']
    refute_nil title_0, "have title"
    assert_operator title_0.length, '>', 0, "title has length"
  end

end
