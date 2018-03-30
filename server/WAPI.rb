# Utility class to run requests against a WSO2 API.
# This has two entry points of interest:

# Constructor: new(hash)
# The hash should contain the following values:
# 'token_server','api_prefix','key','secret'
# It may contain the current token value but does not need to
# since WAPI will renew tokens as necessary.

# get_request(string): This string will be appended to the api_prefix and
# executed as a GET

# See the WAPI_result_wrapper class code for the output format.  The data for a request
# is expected to be returned as a JSON string.

# Only GET is explicitly supported at the moment. (Internally it also uses a POST to renew tokens.)

require 'base64'
require 'rest-client'
require "link_header"
require_relative './Logging'
require_relative './WAPI_result_wrapper'
require_relative './WAPI_status'
require_relative './stopwatch'

## For detailed tracing set this to anything but FalseClass
TRACE=FalseClass

include Logging

class WAPI

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

    logger.debug("application: #{application}")
    
    @token_server = application['token_server']
    @api_prefix = application['api_prefix']
    @key = application['key']
    @secret = application['secret']
    @token = application['token']
    # # added for IBM Api manager
    # # client_id and client_secret will be key and secret
    @scope = application['scope']
    @grant_type = application['grant_type']
    #
    if (@scope.nil?)
      logger.error("missing value: scope")
      raise "WAPI: missing value: scope"
    end
    if (@grant_type.nil?)
      logger.error("missing value: grant_type") if (@grant_type.nil?)
      raise "WAPI: missing value: grant_type"
    end
    #
    # ## special uniqname may be supplied for testing
    @uniqname = application['uniqname']
    #
    @renewal = WAPI.build_renewal(@key, @secret)
    logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: initialized WAPI with #{@api_prefix}")
  end

  def self.build_renewal(key, secret)
    b64 = base64_key_secret(key, secret)
    "Basic #{b64}"
  end

  def self.base64_key_secret(key, secret)
    ks = "#{key}:#{secret}"
    Base64.strict_encode64(ks)
  end

  ######### utilities for URL formatting
  # use instance specific configuration information to generate the full url.
  def format_url(request)
    "#{@api_prefix}#{request}"
  end

  # Responses may contain partial results.  In that case information about how to get the remaining data is returned
  # in the 'Link' header. Link headers come back with explicit URLs pointing to Canvas servers.
  # Remove that server added by the external service since we need to send queries back through the ESB rather than
  # straight to the external service.
  # This code assumes that the main portion of the next link (more_url) looks like the original request except that
  # the beginning may be different (e.g. direct to canvas host vs through the ESB proxy) and the query parameters
  # may be different (e.g. maybe add info about where to restart retrieval).

  # A trivial more_url should become an empty string.
  # Query parameters on the more_url should be passed through.
  # Query parameters on the request_string should be ignored.
  # The more_url is a complete URL that was returned from the external service.  The
  # request_string it the partial url generated internally that doesn't have any explicit server / api
  # version information.

  def reduce_url(more_url, request_string)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: more_url: #{more_url} request_string: #{request_string}"

    return "" if more_url.nil? || more_url.length == 0

    # Get the main part of the original request without any query parameters.
    main_request = request_string.index('?') ? request_string[/(^.+)\?/] : request_string

    # Pull out the part of more_url that matches the original query and also pull along query parameters that were
    # supplied in the more_url.
    more_url = more_url[/#{main_request}.*/]

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: reduced more_url: #{more_url}"
    more_url
  end

  # Make a request to an external service and handle error conditions and headers.
  def do_request(request_string)

    RestClient.log = logger if (logger.debug? and TRACE != FalseClass)

    # make the request specific to the separately configured API.
    url=format_url(request_string)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: url: #{url}"
    r = Stopwatch.new(Thread.current.to_s+": "+url)
    r.start
    begin
      response = RestClient.get url, {:Authorization => "Bearer #{@token}",
                                      'x-ibm-client-id' => @key,
                                       :accept => :json,
                                       :verify_ssl => true}

      # If the request has more data pull out the external url to get it.
      more_url = process_link_header(response)
      # fix it up to go through our proxy.
      more_url = reduce_url(more_url, request_string)

      ## try to parse as json.  If can't do that generate an error.
      json_response = JSON.parse(response)

      ## json_response is a JSON object.  Only print part of it.
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: esb response as json"+JSON.generate(json_response)[0..30]

      # fix up the json a bit.
      json_response = standardize_json(json_response, response)

      ####### Now we have a parsed json object
      # figure out the overall response code for the request.  That may come from the esb call or data returned
      # from the request url
      rc = compute_response_code_to_return(json_response, response)

      ## We have parsed JSON, now make it a json string so it can be returned
      json_response = JSON.generate(json_response)

      wrapped_response = WAPIResultWrapper.new(rc, "COMPLETED", json_response, more_url)

        ### handle some error conditions explicitly.
    rescue URI::InvalidURIError => exp
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: invalid URI: "+exp.to_s
      wrapped_response = WAPIResultWrapper.new(WAPIStatus::BAD_REQUEST, "INVALID URL", exp.to_s)

    rescue StandardError => exp
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: exception: "+exp.inspect
      if exp.response.code == WAPIStatus::HTTP_NOT_FOUND
        wrapped_response = WAPIResultWrapper.new(WAPIStatus::HTTP_NOT_FOUND, "NOT FOUND", exp)
      else
        wrapped_response = WAPIResultWrapper.new(WAPIStatus::UNKNOWN_ERROR, "EXCEPTION", exp)
      end
    end

    r.stop
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}:do_request: stopwatch: "+ r.pretty_summary
    wrapped_response
  end


  # A response may provide link headers that indicate the data returned is partial and more is available if you
  # use the 'next' url provided.  Get that link and log some information so we can track this.
  def process_link_header(response)

    linkheader = LinkHeader.parse(response.headers[:link]).to_a

    next_link, last_link = nil, nil

    #### extract the interesting header links
    linkheader.each { |link|
      next_link ||= header_link_for_rel(link, 'next')
      last_link ||= header_link_for_rel(link, 'last')
    }

    # If there is more data on another page log that.
    if !next_link.nil?
      page_estimate = ""
      # Log last_page and per_page values from the 'last' url so can get rough estimate of total number of
      # entries for query. Note: We use the page/per_page information because it turns out that Canvas puts that
      # in the URL. However that isn't a standard and we shouldn't rely on it for processing.
      if !last_link.nil?
        p = Regexp.new(/page=(\d+)&per_page=(\d+)/)
        p.match(last_link)
        last_page, per_page = $1, $2
        page_estimate = "last_page: #{last_page} page_size: #{per_page} "
      end
      logger.warn "#{self.class.to_s}:#{__method__}:#{__LINE__}: pagination: #{page_estimate} next_link: #{next_link}"
    end

    # return the raw next link (or an empty string)
    next_link.nil? ? "" : next_link
  end

  # Utility to extract URL for the desired link type from the full link header.
  def header_link_for_rel(link, desired)
    link[1][0][1] == desired ? link[0] : nil
  end

  ## detailed dump of response object
  def dump_json_object(json_response, response)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: after initial parse"
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: response.code: "+json_response[response.code].to_s
  end

  ## Figure out the response status code to return.  It might be from the response body or from the RestClient response.
  def compute_response_code_to_return(j, response)
    # default to the restClient value
    rc = response.code
    if Hash.try_convert(j)
      # if the whole thing in an error response then pull out the contents
      # of the error response.
      if j.has_key?('ErrorResponse')
        j=j['ErrorResponse']
      end
      # if there is a nested response code then use that.
      if j.has_key?('responseCode')
        rc = j['responseCode']
      end
    end
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: use response code: [#{rc}]"
    rc
  end

  ## Fix up the json a bit.
  def standardize_json(j, response)
    # if there is a nested response code then make sure it is an integer.
    begin
      if (!j.kind_of?(Array) && j.has_key?('responseCode'))
        # returned value may have a response code element that needs to be converted to an integer
        j['responseCode'] = j['responseCode'].to_i
      end
    rescue => err
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: conversion error "+j.inspect
      # because of the error reset j back to the original json response.
      j = JSON.parse(response)
    end
    j
  end

  # Entry point to make the URL request. It may end up making multiple calls to do_request since
  # it may need to deal with authorization / token renewal and with big requests that make
  # many calls in order to get a complete data set.
  # In any case will return a WAPI wrapper result.
  def get_request(request)

    wrapped_response = do_request(request)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: initial request: "+request.to_s

    ## If required try to renew the token and redo the request.
    if wrapped_response.meta_status == WAPIStatus::UNKNOWN_ERROR &&
        wrapped_response.result.respond_to?('http_code') &&
        wrapped_response.result.http_code == WAPIStatus::HTTP_UNAUTHORIZED
      wrapped_response = renew_token()
      ## if the token renewed ok then try the request again.
      if wrapped_response.meta_status == WAPIStatus::SUCCESS
        wrapped_response = do_request(request)
      end
    end

    # If it didn't work just return that information.
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: wrapped_response: meta_status: #{wrapped_response.meta_status}"
    if wrapped_response.meta_status != WAPIStatus::SUCCESS
      return wrapped_response
    end

    ## Ran a query successfully.  See if got partial data and need to keep going.

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: wrapped_response: data length: #{wrapped_response.result.length}"
    # See if there is a link header, if so get the rest of the data.
    if wrapped_response.meta_more.length > 0
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: found link header: >>#{wrapped_response.meta_more}<<"

      more_data = get_request(wrapped_response.meta_more)
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}:  more_data status: #{more_data.meta}"

      if more_data.meta_status == WAPIStatus::SUCCESS
        logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}:  will merge data: initial wrapped_response: #{wrapped_response.result.length} more_data: #{more_data.result.length}"
        wrapped_response = wrapped_response.append_json_results(more_data)
      else
        logger.error "#{self.class.to_s}:#{__method__}:#{__LINE__}: can not merge more_data: #{more_data.inspect}"
      end
    end
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: final wrapped_response: result length: #{wrapped_response.result.length}"
    wrapped_response
  end

  # Renew the current token.  Will set the current @token value in the object
  def renew_token

    begin
      logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: token_server: #{@token_server}")
      response = runTokenRenewalPost
      ## If it worked then parse the result as json.  This is here to capture any JSON parsing exceptions.
      if response.code == WAPIStatus::HTTP_SUCCESS
        ## will need to get the access_token below.  If it is not JSON that is an error.
        s = JSON.parse(response)
        @token = s['access_token']
      end
    rescue Exception => exp
      # If got an exception for the renewal then wrap that up to be returned.
      logger.warn("#{self.class.to_s}:#{__method__}:#{__LINE__}: renewal post exception: "+exp.to_json)
      logger.warn("#{self.class.to_s}:#{__method__}:#{__LINE__}: renewal post exception: "+exp.to_json+":"+exp.http_code.to_s)
      return WAPIResultWrapper.new(exp.http_code, "EXCEPTION DURING TOKEN RENEWAL", exp)
    end

    ## got no response so say that.
    if response.nil?
      logger.warn("#{self.class.to_s}:#{__method__}:#{__LINE__}: error renewing token: nil response ")
      return WAPIResultWrapper.new(WAPIStatus::UNKNOWN_ERROR, "error renewing token: nil response", response)
    end

    # if got an error so say that.
    if response.code != WAPIStatus::HTTP_SUCCESS
      logger.warn("#{self.class.to_s}:#{__method__}:#{__LINE__}: error renewing token: response code: "+response.code)
      return WAPIResultWrapper.new(WAPIStatus::UNKNOWN_ERROR, "error renewing token: response code", response)
    end

    # all ok
    print_token = sprintf "%5s", @token
    logger.debug("#{self.class.to_s}:#{__method__}:#{__LINE__}: renewed token: #{print_token}")
    return WAPIResultWrapper.new(WAPIStatus::SUCCESS, "token renewed", response)
  end


  ## Uses global class instance variables for these values for now
  def runTokenRenewalPost
    msg = Thread.current.to_s
    renew = Stopwatch.new(msg)
    renew.start
    payload = "grant_type=#{@grant_type}&scope=#{@scope}&client_id=#{@key}&client_secret=#{@secret}"
    response = RestClient.post @token_server,
                               payload,
                               {
                                   :content_type => "application/x-www-form-urlencoded"
                               }
  ensure
    # make sure to print the elapsed time for the renewal.
    renew.stop
    logger.info("WAPI: renew token post: stopwatch: "+renew.pretty_summary)
  end

end
