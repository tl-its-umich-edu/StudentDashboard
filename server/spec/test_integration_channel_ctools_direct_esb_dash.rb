require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'


require 'yaml'
require 'JSON'
require 'RestClient' ## This is required if want to set the RestClient logger.
#require_relative '../channel_ctools_direct_http'

require_relative '../Logging'
require_relative 'test_helper'
require_relative '../WAPI'

include Logging

##############################################################################
## This suite tests the functioning of the HTTP channel. This tests the specific
## requests to ctools.
##############################################################################

class TestIntegrationChannelCToolsDirectESBDash < Minitest::Test

  @@yml_file = TestHelper.findSecurityFile("security.yml")
  logger.debug "yml_file: #{@@yml_file}"
  @@yml = nil
  @@config = nil

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
    @uniqname = application['uniqname']
    #logger.debug "#{__LINE__}: la: token: #{@token} key: #{@key} secret: #{@secret}"
  end

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

    # Setup logging.  May override explicitly for single test or for RestClient.
    logger.level = TestHelper.getCommonLogLevel

    #logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG
    #RestClient.log = logger ### Uncomment this to see the RestClient logging.

    # setup common variables
    ## ERROR: USE NEW APPLICATION
    @esb_application = "SD-QA"
    #@esb_application = "DEV-ESB-TEST-DLH-CTOOLS"
    #@esb_application = "CtoolsAdmin-DEV"
    #CtoolsAdmin-DEV
    @security_file = TestHelper.findSecurityFile "security.yml"

    load_yml
    load_application @esb_application

    @default_term = "2060"

    a = Hash['api_prefix' => @api_prefix,
             'key' => @key,
             'secret' => @secret,
             'token_server' => @token_server,
             #'token' => '!sweet',
             'token' => @token
    ]


    # def setupCToolsWAPI(app_name)
    #   logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: setupCToolsWAPI: use ESB application: #{app_name}"
    #   application = @@yml[app_name]
    #   @@w = WAPI.new application
    # end

    # Get a session setup with the specified application / account.  The
    # session user is specified in the account in the security file.
    # Change to a new specific user.
    #@ctools_direct = ChannelCToolsDirectHTTP.new(@security_file, @http_application)
    @ctools_esb = WAPI.new(a)



    @new_user = 'studenta'
    # change to the user of interest
    @ctools_response = @ctools_esb.get_request("/session/becomeuser/#{@new_user}.json")
    puts "become user: ctools_RESPONSE: ["+@ctools_response.inspect+"]"


  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_http_direct_get_session_information

    skip ("not implemented")
    # verify that user for the session can be changed and is the new one as expected.
    response = @ctools_esb.get_request("/session.json")
    puts "response: [@{response.value_as_json}]"
    json_response = JSON.parse response
    session_userEid = json_response['session_collection'][0]['userEid']
    assert_equal @new_user, session_userEid, "match current session user with user: #{@new_user}"
  end

  def test_http_direct_get_dash_calendar
    skip ("not implemented")
    # get the dash calendar information
    response = @ctools_esb.get_request("/dash/calendar.json")
    puts "RESPONSE: ["+response.inspect+"]"
    json_response = JSON.parse response.value_as_json
    logger.debug "ctools dash calendar json: "+json_response.inspect
    # There may be no current calendar events, but there should be some valid json response.
    assert_equal "dash", json_response['entityPrefix'], "confirm response is from ctools dashboard"
  end

  def test_http_direct_get_dash_news
    skip ("not implemented")
    # get the dash news information
    response = @ctools_esb.get_request("/dash/news.json")
    json_response = JSON.parse response
    logger.debug "ctools dash news json: "+json_response.inspect
    # There may be no current dash news, but there should be some valid json response.
    assert_equal "dash", json_response['entityPrefix'], "confirm response is from ctools dashboard"
  end

end
##################### end #####################
