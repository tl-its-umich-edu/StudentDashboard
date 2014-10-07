# Utility class to run requests against a WSO2 API.
# It will automatically renew the token if it doesn't work.  The
# public entry points are:

# Constructor: initialize(api_prefix, key, secret, token_server, token="Toker")
# Initialize the class with the api prefix which will be prepended to
# every request.  The prefix may just point to the gateway or may
# point to a specific API.
# The constructor also requires the key, secret and token server API.
# You may pass a specific token but this is not required since the
# class will automatically try to renew the token if it finds a request fails.

# get_request(string): This string will be appended to the api_prefix and
# executed as a GET

require 'Base64'
require 'rest-client'

class WAPI

  # key and secret are oauth key and secret for generating tokens.
  # token_server is full url for request to generate / renew tokens.
  #
  # api_prefix is string that will be prefixed to every request make
  # through this instance.  It will contain host and may anything else
  # that will appear in front of every request.  E.g. It might contain
  # https://woodpigeon.dsc.umich.edu:8243/StudentDashboard/v1 or just
  # https://woodpigeon.dsc.umich.edu:8243 depending on how you choose
  # to use it.

  # default token value
  def initialize(api_prefix, key, secret, token_server, token="Toker")
    @api_prefix = api_prefix
    @key = key
    @secret = secret
    @token_server = token_server
    @token = token
    @renewal = WAPI.build_renewal(@key, @secret)
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

  ## try the request
  def do_request(request)
#    puts "WAPI: do_request: #{request}"
    url=format_url(request)
    response = RestClient.get url, {:Authorization => "Bearer #{@token}",
                                    :accept => :json,
                                    :verify_ssl => true}
  end

  ## run the request and renew token if it has expired and can be renewed
  def get_request(request)

    begin
      response = do_request(request)
    rescue
      # Try fixing up the token authorization
      renew_token
      response = do_request(request)
    end

 #   puts "WAPI: gr: " + response.to_s
    response
  end

# Renew the current token.  Will set the current @token value in the object
  def renew_token

#    puts "WAPI: renewing token"
    response = RestClient.post @token_server,
                               "grant_type=client_credentials&scope=PRODUCTION",
                               {
                                   :Authorization => @renewal,
                                   :content_type => "application/x-www-form-urlencoded"
                               }
 #   puts "WAPI: status code:"+response.code.to_s
    s = JSON.parse(response)

#    puts "WAPI: s: "+s.to_s
    if response.code != 200
      puts "error renewing token"
    else
      @token = s['access_token']
      puts "WAPI: renewed token @token"
    end
  end

end
