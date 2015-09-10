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
## Tests for the class that makes calls to the CTools direct api through HTTP.
## This suite tests the functioning of the HTTP channel.  It doesn't test the
## requests we want to make of CTools.
##############################################################################

class TestIntegrationChannelCToolsDirectHttp < Minitest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

    logger.level = TestHelper.getCommonLogLevel
    #logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG
    #RestClient.log = logger ### Uncomment this to see the RestClient logging.

    @http_application = "CTQA-DIRECT"
    @security_file = TestHelper.findSecurityFile "security.yml"

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_http_direct_new_creates_session
    hdn = ChannelCToolsDirectHttp.new(@security_file, @http_application)
    refute_nil(hdn)
    assert_operator 0, "<", hdn.session_id.length, "get session id"
  end

  def test_http_direct_new_fails_on_bad_application_name
    hdn = ChannelCToolsDirectHttp.new(@security_file, "KinkyBoots")
    assert_nil hdn.session_id, "invalid application name"
  end

  def test_http_direct_new_fails_on_bad_security_file_name
    assert_raises Errno::ENOENT do
      ChannelCToolsDirectHttp.new("badboys", "KinkyBoots")
    end
  end

  def test_http_direct_get_session_information
    hdn = ChannelCToolsDirectHttp.new(@security_file, @http_application)
    # get the response from the request
    response = hdn.do_request("/session.json")
    refute_nil response, "get session information"
    # parse that as json into a Ruby data structure.
    json_response = JSON.parse response
    refute_nil json_response, " got json response for session"
    # make sure the  has something expected is found in the response
    session_userEid = json_response['session_collection'][0]['userEid']
    assert_equal hdn.user, session_userEid, "match current session user with initial user"
  end

  def test_http_direct_delete_session
   # skip "end / delete session will be implemented only if necessary"
    end

end
