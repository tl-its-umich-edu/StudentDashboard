require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'


require 'yaml'
require 'JSON'
require 'RestClient' ## This is required if want to set the RestClient logger.
require_relative '../channel_ctools_direct_http'

require_relative '../Logging'
require_relative 'test_helper'

include Logging

##############################################################################
## This suite tests the functioning of the HTTP channel. This tests the specific
## requests to ctools.
##############################################################################

class TestIntegrationChannelCToolsDirectHttpDash < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

    # Setup logging.  May override explicitly for single test or for RestClient.
    logger.level = TestHelper.getCommonLogLevel
    #logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG
    #RestClient.log = logger ### Uncomment this to see the RestClient logging.

    # setup common variables
    @http_application = "CTQA-DIRECT"
    @security_file = TestHelper.findSecurityFile "security.yml"
    @new_user = "dlhaines"

    # create the class
    #m = Class.new do
    #      include ChannelCToolsDirectHttp
    #      include Logging
    #    end.new

    # Get a session setup with the specified application / account.  The
    # session user is specified in the account in the security file.
    # Change to a new specific user.
    @ctools_direct = ChannelCToolsDirectHTTP.new(@security_file, @http_application)
    # change to the user of interest
    @ctools_response = @ctools_direct.do_request("/session/becomeuser/#{@new_user}.json")

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_http_direct_get_session_information

    # verify that user for the session can be changed and is the new one as expected.
    response = @ctools_direct.do_request("/session.json")
    json_response = JSON.parse response
    session_userEid = json_response['session_collection'][0]['userEid']
    assert_equal @new_user, session_userEid, "match current session user with user: #{@new_user}"
  end

  def test_http_direct_get_dash_calendar

    # get the dash calendar information
    response = @ctools_direct.do_request("/dash/calendar.json")
    json_response = JSON.parse response
    logger.debug "ctools dash calendar json: "+json_response.inspect
    # There may be no current calendar events, but there should be some valid json response.
    assert_equal "dash", json_response['entityPrefix'], "confirm response is from ctools dashboard"
  end

  def test_http_direct_get_dash_news

    # get the dash news information
    response = @ctools_direct.do_request("/dash/news.json")
    json_response = JSON.parse response
    logger.debug "ctools dash news json: "+json_response.inspect
    # There may be no current dash news, but there should be some valid json response.
    assert_equal "dash", json_response['entityPrefix'], "confirm response is from ctools dashboard"
  end

end
##################### end #####################
