###### CTools direct URL provider ################
# Implement handling of CTools direct url queries directly over http.  Creates a session then automatically adds that to each request
# until the end method is called.  The session id is invisible to the user.
# Creating a new instance of the class creates a session.
# The 'app_name' specifies the configuration to use in the supplied security_file.  Configuration
# requires an admin user / pw and a url prefix that will be prefixed to the url passed into do_request.

# public methods:
# - initialize(security_file, app_name) - initialize connection based on parameters from this file.
# - do_request(url) -
# - end - close down the connection / session (currently unimplemented, not clear if appropriate)

require_relative './Logging'
require 'rest-client'
require_relative 'stopwatch'

# TODO: I've not figured out how to use instance variables from a module yet, so this is implemented as a class.
class ChannelCToolsDirectHTTP

  # instance will require a session id from CTools along with the
  # account information.

  attr_accessor :session_id, :user

  # Setup the connection based on configuration information.
  # This requires the name of the security configuration file and the name of a specific section in that file.
  # If the application is not found the session_id will be nil.
  def initialize(security_file, app_name)
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: use direct url application: #{app_name}"
    application = getApplication(security_file, app_name)
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: application: #{application}"

    return nil if application.nil?

    @user = application['userid']
    @password = application['password']
    @url_prefix = application['url_prefix']

    # need to get a session in order to make queries.
    runGetCToolsSession
  end

  # Get the configuration information required from the yaml file.
  def getApplication(security_file, app_name)

    requested_file = security_file

    default_security_file = './server/local/security.yml'

    if File.exist? requested_file
      file_name = requested_file
    else
      file_name = default_security_file
    end

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: use security file_name: #{file_name}"

    security_info = YAML.load_file(file_name)
    app_info = security_info[app_name]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: app_info: "+app_info.inspect
    if app_info.nil?
      logger.error "#{self.class.to_s}:#{__method__}: NO SUCH APPLICATION NAME: security_file: #{file_name} application: #{app_name}"
    end
    app_info
  end

  # Use configuration information to generate the proper complete url.
  def format_url(request)
    "#{@url_prefix}#{request}"
  end

  # Create a new CTools session
  def runGetCToolsSession
    #RestClient.log = logger ### Uncomment this to see the RestClient logging.

    # Get a ctools session for the uber user.
    use_url = format_url "/session.json"

    elapsed = Stopwatch.new(Thread.current.to_s+": "+use_url)
    elapsed.start

    # pass post data via parameters to get correct uri encoding.
    @session_id = RestClient.post use_url, {:"_username" => @user, :"_password" => @password},
                                  {:verify_ssl => true, :content_type => 'multipart/form-data'}

    # make sure to print the elapsed time for the renewal.
    elapsed.stop
    logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: get session id post: stopwatch: "+elapsed.pretty_summary)
  end

  def do_request(request)
    # If the request already has the query character '?' add session with a '&', otherwise use a '?'
    glue_character = '?'

    if request.include? '?'
      glue_character = '&'
    end

    url = format_url(request)+"#{glue_character}_sessionId=#{@session_id}"
    logger.debug("#{self.class.to_s}:#{__method__}:#{__LINE__}: url: "+url)
    elapsed = Stopwatch.new(Thread.current.to_s+": "+url)
    elapsed.start
    response = RestClient.get url, :verify_ssl => true
    elapsed.stop
    logger.info("#{self.class.to_s}:#{__method__}:#{__LINE__}: response: stopwatch: "+elapsed.pretty_summary)
    response
  end

end
