# Utility class to run requests against a WSO2 API.
# This has two entry points of interest:

# Constructor: new(hash)
# The hash should contain the following values:
# 'token_server','api_prefix','key','secret'
# It may contain the current token value but does not need to
# since WAPI will renew tokens as necessary.

# get_request(string): This string will be appended to the api_prefix and
# executed as a GET

# Only GET is explicitly supported at the moment.

require 'base64'
require 'rest-client'
require_relative './Logging'

include Logging

class WAPI

  # key and secret are oauth key and secret for generating tokens.
  # token_server is full url for request to generate / renew tokens.
  #
  # api_prefix is string that will be prefixed to every request made
  # through this instance.  It will contain host and may anything else
  # that will appear in front of every request.  E.g. It might contain
  # https://woodpigeon.dsc.umich.edu:8243/StudentDashboard/v1 or just
  # https://woodpigeon.dsc.umich.edu:8243 depending on how you choose
  # to use it.

  def initialize(application)
    #puts "in WAPI initialize"
    if application.nil?
      msg = "No ESB Application values provided to WAPI initialize"
      logger.warn msg
      raise StandardError, msg
    end

    @token_server = application['token_server']
    @api_prefix = application['api_prefix']
    @key = application['key']
    @secret = application['secret']
    @token = application['token']

    # ## special uniqname may be supplied for testing
    @uniqname = application['uniqname']

    @renewal = WAPI.build_renewal(@key, @secret)
    logger.info("initialize WAPI with #{@api_prefix}")
  end

  def self.build_renewal(key, secret)
    b64 = base64_key_secret(key, secret)
    "Basic #{b64}"
  end

  def self.base64_key_secret(key, secret)
    ks = "#{key}:#{secret}"
    Base64.strict_encode64(ks)
  end

# use instance information to generate the proper url
  def format_url(request)
    "#{@api_prefix}#{request}"
  end

  ## internal method to actually make the request
  def do_request(request)
    url=format_url(request)
    logger.debug "WAPI: do_request: url: #{url}"
    response = RestClient.get url, {:Authorization => "Bearer #{@token}",
                                    :accept => :json,
                                    :verify_ssl => true}
  end

  ## run the request and try to renew token if it has expired.
  def get_request(request)

    begin
      response = do_request(request)
      logger.debug("WAPI: response: "+response.inspect)
        ## check out error conditions
    rescue RestClient::Unauthorized => una
      # Try fixing up the token since authorization failed.
      renew_token
      begin
        response = do_request(request)
      rescue StandardError => nested_se
        logger.debug "rescue nested request" + nested_se.inspect
      end
    rescue StandardError => se
      # reraise other exceptions
      logger.debug "WAPI: StandardError: "+se.inspect
      raise se
    end
    logger.debug 'WAPI: response'+response.inspect
    response
  end

# Renew the current token.  Will set the current @token value in the object
  def renew_token

    #puts "WAPI: renewing token: #{@token}"
    logger.debug "WAPI: renew_token"
    response = RestClient.post @token_server,
                               "grant_type=client_credentials&scope=PRODUCTION",
                               {
                                   :Authorization => @renewal,
                                   :content_type => "application/x-www-form-urlencoded"
                               }
    s = JSON.parse(response)

    if response.code != 200
      logger.warn("error renewing token"+response.inspect)
    else
      @token = s['access_token']
      logger.debug("renewed token #{@token}")
    end
  end

end
