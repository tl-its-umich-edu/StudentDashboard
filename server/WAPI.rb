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
require_relative './WAPI_result_wrapper'
require_relative './stopwatch'

## For detailed tracing set this to anything but FalseClass
TRACE=FalseClass

include Logging

class WAPI

  # Constants for the status value of the wrapper. The potential
  # errors / status can be different so they need not be the same
  # as the HTTP_STATUS.  These are referenced with the namespace
  # WAPI:: for consistency across modules.  E.g. WAPI::UNKNOWN_ERROR.
  SUCCESS = 200
  UNKNOWN_ERROR = 666
  BAD_REQUEST = 400

  # Constants for the http status of the underlying request.
  HTTP_SUCCESS = 200
  HTTP_UNAUTHORIZED = 401
  HTTP_NOT_FOUND = 404

  # The application provides the values required to make a connection
  # to the WSO2 ESB.  The key and secret are oauth key and secret for generating tokens.
  # The token_server is full url for request to generate / renew tokens.
  #
  # The api_prefix is string that will be prefixed to every request made
  # through this instance.  It will contain host and anything else
  # that will appear in front of every request.  E.g. It might contain
  # https://woodpigeon.dsc.umich.edu:8243/StudentDashboard/v1 or just
  # https://woodpigeon.dsc.umich.edu:8243 depending on how you choose
  # to use it.

  def initialize(application)
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
    logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: initialize WAPI with #{@api_prefix}")
  end


  ### Consider making this a separate class with helpful methods
  ### to access portions of the result and to convert types.
  def self.wrap_result(status, msg, result)
    Hash["Meta" => Hash["httpStatus" => e,
                        "Message" => msg],
         "Result" => result]
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

  def do_request(request)

    RestClient.log = logger if (logger.debug? and TRACE != FalseClass)

    url=format_url(request)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: url: #{url}"
    msg = Thread.current.to_s+": "+url
    r = Stopwatch.new(msg)
    r.start
    begin
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: get url: #{url}"
      response = RestClient.get url, {:Authorization => "Bearer #{@token}",
                                      :accept => :json,
                                      :verify_ssl => true}

      ## try to parse as json.  If can't do that generate an error
      json_response = JSON.parse(response)

      ## json_response is a JSON object
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: esb response as json"+JSON.generate(json_response)

      # fix up the json a bit.
      json_response = standardize_json(json_response, response)

      ####### Now we have a parsed json object
      dump_json_object(json_response, response) if logger.debug;

      # figure out the overall response code for the request.
      rc = compute_response_code_to_return(json_response, response)

      ## We have parsed JSON, now make it a json string so it can be returned
      json_response = JSON.generate(json_response)
      wrapped_response = WAPIResultWrapper.new(rc, "COMPLETED", json_response)

        ### handle error conditions explicitly.
    rescue URI::InvalidURIError => exp
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: invalid URI: "+exp.to_s
      wrapped_response = WAPIResultWrapper.new(WAPI::BAD_REQUEST, "INVALID URL", exp.to_s)

    rescue Exception => exp
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: exception: "+exp.inspect
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: exception: st: "+exp.backtrace.to_s

      if exp.response.code == WAPI::HTTP_NOT_FOUND
        wrapped_response = WAPIResultWrapper.new(WAPI::HTTP_NOT_FOUND, "NOT FOUND", exp)
      else
        wrapped_response = WAPIResultWrapper.new(WAPI::UNKNOWN_ERROR, "EXCEPTION", exp)
      end
    end

    r.stop
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}:do_request: stopwatch: "+ r.pretty_summary
    wrapped_response
  end

  ## detailed dump of response object
  def dump_json_object(json_response, response)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: after initial parse"
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: response.code: "+json_response[response.code].to_s
    #json_response.each { |x| puts "x: #{x}" } if (TRACE != FalseClass)
  end

  ## Figure out the response status code to return.  It might be from the response body or from the RestClient response.
  def compute_response_code_to_return(j, response)
    if Hash.try_convert(j)
      # if there is a nested response code then use that.
      if j.has_key?('responseCode')
        rc = j['responseCode']
      else
        # use the one from the request to the esb.
        rc = response.code
      end
    end
    rc
  end

  ## Fix up the json a bit.
  def standardize_json(j, response)
    # if there is a nested response code then make sure it is an integer.
    begin
      if  ( !j.kind_of?(Array) && j.has_key?('responseCode') )
        # returned value may have a response code element that needs to be converted to an integer
          j['responseCode'] = j['responseCode'].to_i
      end
    rescue => err
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: conversion error "+j.inspect
      ## because of the error reset j back to the original json response.
      j = JSON.parse(response)
    end
    j
  end


  ## Run the request.  If the result is unauthorized then renew the token and try again.
  ## In any case will return a wrapped result.

  def get_request(request)
    wrapped_response = do_request(request)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: get_request: "+request.to_s

    ## If appropriate try to renew the token.
    if wrapped_response.meta_status == WAPI::UNKNOWN_ERROR &&
        wrapped_response.result.respond_to?('http_code') &&
        wrapped_response.result.http_code == HTTP_UNAUTHORIZED
      wrapped_response = renew_token()
      ## if the token renewed ok then try the request again.
      if wrapped_response.meta_status == WAPI::SUCCESS
        wrapped_response = do_request(request)
      end
    end
    wrapped_response
  end

  # Renew the current token.  Will set the current @token value in the object
  def renew_token

    begin
      logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: token_server: #{@token_server}")
      response = runTokenRenewalPost
      ## If it worked then parse the result as json.  This is here to capture any JSON parsing exceptions.
      if response.code == HTTP_SUCCESS
        ## will need to get the access_token below.  If it is not JSON that is an error.
        s = JSON.parse(response)
        @token = s['access_token']
      end
    rescue Exception => exp
      # If got an exception for the renewal then wrap that up to be returned.
      logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: renewal post exception: "+exp.to_json+":"+exp.http_code.to_s)
      return WAPIResultWrapper.new(exp.http_code, "EXCEPTION DURING TOKEN RENEWAL", exp)
    end

    ## got no response so say that.
    if response.nil?
      logger.warn("#{self.class.to_s}:#{__method__}:#{__LINE__}: error renewing token: nil response ")
      return WAPIResultWrapper.new(WAPI::UNKNOWN_ERROR, "error renewing token: nil response", response)
    end

    # if got an error so say that.
    if response.code != HTTP_SUCCESS
      logger.warn("#{self.class.to_s}:#{__method__}:#{__LINE__}: error renewing token: response code: "+response.code)
      return WAPIResultWrapper.new(WAPI::UNKNOWN_ERROR, "error renewing token: response code", response)
    end

    # all ok
    print_token = sprintf "%5s", @token
    logger.debug("#{self.class.to_s}:#{__method__}:#{__LINE__}: renewed token: #{print_token}")
    return WAPIResultWrapper.new(WAPI::SUCCESS, "token renewed", response)
  end


  ## Uses global class instance variables for these values for now
  def runTokenRenewalPost
    msg = Thread.current.to_s
    renew = Stopwatch.new(msg)
    renew.start;
    response = RestClient.post @token_server,
                               "grant_type=client_credentials&scope=PRODUCTION",
                               {
                                   :Authorization => @renewal,
                                   :content_type => "application/x-www-form-urlencoded"
                               }
  ensure
    # make sure to print the elapsed time for the renewal.
    renew.stop;
    logger.info("WAPI: renew token post: stopwatch: "+renew.pretty_summary)
  end

end
