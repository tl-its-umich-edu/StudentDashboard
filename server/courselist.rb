## These lines make the required modules available.
require File.expand_path(File.dirname(__FILE__) + '/data_provider_esb.rb')
require File.expand_path(File.dirname(__FILE__) + '/data_provider_file.rb')

### Simple rest server for SD data.
### This version will also server up the HTML page if no
### specific page is requested.

### Configuration will be read in from /usr/local/ctools/app/ctools/tl/home/studentdashboard.yml file if available
### or from ./server/local/studentdashboard.yml in the build if necessary.

### Sinatra is a DSL (domain specific language) for working with HTTP requests.

require 'sinatra'
require 'json'
require 'slim'
require 'yaml'
require_relative 'stopwatch'
require_relative 'WAPI'
require_relative 'WAPI_result_wrapper'
require_relative 'ldap_check'

include Logging

class CourseList < Sinatra::Base
  ## mixin the providers functionality.
  include DataProviderESB
  include DataProviderFile

  # To store persistent configuration values in Sinatra requires using the settings feature.
  # To make all our configuration values available we store a hash of all the
  # configuration values using settings and access the values through that hash.

  ## These configuration values are defined with default values but can, and
  ## often are, overridden by values in the configuration yml files.  The default
  ## values are designed to be useful for development.

  ## Reading configuration files and overriding values is currently clunky and may be addressed in a
  ## separate jira.

  #### Setup default values.
  ## Will store configuration settings in this hash.
  config_hash = Hash.new

  # Will store the hash in the Sinatra settings object so it is available
  # where needed.
  set :latte_config, config_hash

  # Location to find the configuration files.  This can't be overridden by values
  # in the configuration file because this is what identifies the location
  # of the file to read.
  config_base ||= '/usr/local/ctools/app/ctools/tl/home'

  # forbid/allow specifying a different user on request url
  config_hash[:authn_uniqname_override] = false

  ### response to query that is not understood.
  config_hash[:invalid_query_text] = "invalid query. what U want?"

  ## base directory to ease referencing files in the
  ## build.
  config_hash[:BASE_DIR] = File.dirname(File.dirname(__FILE__))

  # name of application to use for information
  config_hash[:application_name] = "SD-QA"

  # default name of default user
  config_hash[:default_user] = "default"

  # default location for student dashboard configuration
  config_hash[:studentdashboard] = "#{config_base}/studentdashboard.yml"

  # location for yml file describing the build.
  config_hash[:build_file] = "#{config_base}/build.yml"

  # default location for the security information
  config_hash[:security_file] = "#{config_base}/security.yml"

  # default location for file containing display strings.
  config_hash[:strings_file] = "#{config_base}/strings.yml"

  config_hash[:log_file] = "server/log/sinatra.log"

  config_hash[:default_term] = 2010

  # Hold data required if need to put in a wait to simulate authn
  # processing time.
  config_hash[:authn_prng] = nil
  config_hash[:authn_total_wait_time] = 0
  config_hash[:authn_total_stub_calls] = 0

  ## potential list of user with admin privileges.
  config_hash[:admin_members] = nil

  ## location of the data files.
  config_hash[:data_provider_file_directory] = nil

  config_hash[:latte_admin_group] = nil

  # initial default
  config_hash[:use_log_level] = "DEBUG"

  ## api docs
  config_hash[:apidoc] = <<END

<p/>
HOST://api - this documentation.
 <p/>
HOST://courses/{uniqname}.json - An array of (fake) course data for this person.  The
query parameter of TERMID=<termid> should be provided.
 <p/>
HOST://terms - returns a list of terms for the current user
<p/>
HOST://terms/{uniqname}.json - return a list of terms for the specified user.
<p/>
HOST://settings - dump data to the log.
<p/>

END

  ## This method will return the contents of the requested (or default) configuration file.
  ## Methods in a Sinatra module need to be defined in a helpers section.
  helpers do

    def self.verify_file_is_usable(requested_file)
      ((File.exists? requested_file) && File.readable?(requested_file)) ? requested_file : nil
    end

    def self.get_local_config_yml(requested_file, default_file, required)

      file_name = verify_file_is_usable(requested_file) || verify_file_is_usable(default_file) || nil

      if file_name.nil? then
        logger.fatal "can not find requested or default configuration file: [#{requested_file}] or [#{default_file}]" if required
        return nil
      end

      logger.info "config: use file: [#{file_name}]"
      YAML.load_file(file_name)

    end

  end

  #### Use the Ruby approach to configuring environment.

  set :environment, :development

  ## Set the environment from an environment variable.
  set :environment, ENV['RACK_ENV'].to_s

  ## need session for authn testing
  configure do
    enable :sessions
  end

  ## Utility methods.  The "self." in the method name means that this is
  ## a class method.

  def self.configureLogging

    ## In Tomcat commenting these three will make output show up in localhost log.

    config_hash = settings.latte_config
    log = File.new(config_hash[:log_file], "a+")
    $stdout.reopen(log)
    $stderr.reopen(log)

    $stderr.sync = true
    $stdout.sync = true
  end

  # Allow resetting the log level based on a string and ignoring case. If the
  # string doesn't make sense it just logs a message.

  def self.setLoggingLevel (use_log_level)

    # anything to do?
    return if use_log_level.nil?;
    return if use_log_level.size == 0;

    # Keep the old level in case the new level doesn't make sense.
    starting_log_level = logger.level

    # update log level based on the string value passed in.
    use_log_level.upcase!
    logger.level = case use_log_level
                     when "DEBUG" then
                       Logger::DEBUG
                     when "INFO" then
                       Logger::INFO
                     when "WARN" then
                       Logger::WARN
                     when "ERROR" then
                       Logger::ERROR
                     when "FATAL" then
                       Logger::FATAL
                     when "UNKNOWN" then
                       Logger::UNKNOWN
                     else
                       logger.error("log level requested is not understood: #{use_log_level}");
                       starting_log_level
                   end

    set :logging, logger.level

  end

  def self.configureStatic

    f = File.dirname(__FILE__)+"/../UI"
    logger.debug("UI files: "+f)
    set :public_folder, f

    config_hash = settings.latte_config

    ## Set early because it will not change.
    config_hash[:server] = Socket.gethostname

    ## Reading configuration files and overriding values is currently clunky and may be addressed in a
    ## separate jira.

    # read in yml configuration into a class variable
    external_config = self.get_local_config_yml(config_hash[:studentdashboard], "./server/local/studentdashboard.yml", true)

    config_hash[:use_log_level] = external_config['use_log_level'] || "INFO"

    setLoggingLevel(config_hash[:use_log_level]);

    # override default values from configuration file if they are specified.
    config_hash[:default_user] = external_config['default_user'] || "anonymous"
    config_hash[:invalid_query_text] = external_config['invalid_query_text'] || config_hash[:invalid_query_text]
    config_hash[:authn_uniqname_override] = external_config['authn_uniqname_override'] || config_hash[:authn_uniqname_override]
    config_hash[:application_name] = external_config['application_name'] || config_hash[:application_name]

    ## See if wait times are set for authn stub wait.
    config_hash[:authn_wait_min] = external_config['authn_wait_min'] || 0
    config_hash[:authn_wait_max] = external_config['authn_wait_max'] || 0

    #### setup information for providers
    ## configuration information for the file data provider. If not provided then a different
    ## provider will be used.
    config_hash[:data_provider_file_directory] = external_config['data_provider_file_directory'] || nil

    config_hash[:latte_admin_group] = external_config['latte_admin_group'] || nil
    logger.debug "admin group is: #{config_hash[:latte_admin_group]}"

    ## If the full path to the provider directory was specified then use it.
    ## Otherwise append what was provided to the local base directory
    if !(config_hash[:data_provider_file_directory].nil? || config_hash[:data_provider_file_directory].start_with?('/'))
      config_hash[:data_provider_file_directory] = "#{config_hash[:BASE_DIR]}/#{config_hash[:data_provider_file_directory]}"
    end

    ##### setup information for authn override
    ## If there is an authn wait specified then setup a random number generator.
    ## create a variable with a random number generator
    if config_hash[:authn_uniqname_override] && (config_hash[:authn_wait_min] > 0 || config_hash[:authn_wait_max] > 0)
      config_hash[:authn_prng] = Random.new
      logger.debug "authn wait range is: #{config_hash[:authn_wait_min]} to #{config_hash[:authn_wait_max]}"
    end

    config_hash[:admin] = external_config['admin'] || []

    config_hash[:default_term] = external_config['default_term'] || config_hash[:default_term]

    # read in yml for the build configuration into a class variable
    begin
      config_hash[:build] = self.get_local_config_yml(config_hash[:build_file], "./server/local/build.yml", false)
      logger.info "build.yml file is optional"
      config_hash[:build_time] = config_hash[:build]['time']
      config_hash[:build_id] = config_hash[:build]['tag'] || config_hash[:build]['last_commit']
    rescue
      # The file only needs to be there when a build has been done.  If it isn't there
      # then just use default values.
      config_hash[:build] = "no build file specified"
      config_hash[:build_time] = Time.now
      config_hash[:build_id] = 'development'
    end

    ## read in yml for the strings into a class variable.
    begin
      config_hash[:strings] = self.get_local_config_yml(config_hash[:strings_file], "./server/local/strings.yml", true)
    rescue
      logger.warn "No strings yml configuration file found"
      config_hash[:strings] = Hash.new()
    end

  end

  #set :threaded true
  ## make sure logging is available
  configure :test do

    #set :logging, Logger::INFO
    #set :logging, Logger::DEBUG

    #configureLogging

    ## look for the UI files in a parallel directory.
    ## this may not be necessary.
    configureStatic
    #set :logging, Logger::INFO
    #set :logging, Logger::DEBUG
  end

  ## make sure logging is available in localhost
  configure :production, :development do

    #set :logging, Logger::INFO
    #set :logging, Logger::DEBUG
    configureStatic

  end

  ## make sure logging is available to sinatra.log
  configure :development do

    configureLogging

    #set :logging, Logger::INFO
    #set :logging, Logger::DEBUG
    configureStatic

  end


  #### Authorization
  # In production the StudentDashboard requires that the user be authenticated.  It verifies this by using the
  # name set in the REMOTE_USER environment variable.  If that variable has no value it will be set to the
  # default user name configured in the studentdashboard.yml file.

  # The Student Dashboard UI makes REST calls back to the application to get data.  These calls are checked to ensure
  # that the call only requests data for the authenticated userid.  The list of users that can override this restriction
  # is supplied by an mcommunity LDAP group named in the studentdashboard.yml file.

  # To ease load testing there are a couple of authentication options that can be configured.  See the
  # studentdashboard.yml file for information on using those.

  ### Add helper instance methods
  helpers do

    def allow_uniqname_override user

      settings.latte_config[:authn_uniqname_override] == true || admin_user(user)
    end

    ## This will use the UNIQNAME query parameter to set the user considered to be authenticated.  It should
    ## only be invoked in a test setting. It's use can be configured in the studentdashboard.yml file.
    def uniqnameOverride

      config_hash = settings.latte_config
      # See if there is a candidate to use as authenticated userid name.
      uniqname = params['UNIQNAME']
      logger.debug "#{__LINE__}:found uniqname: #{uniqname}"

      # don't reset userid if don't have a name to reset it to.
      pass if uniqname.nil? || uniqname.length == 0

      # don't reset if not necessary.  This prevents infinite loops.
      pass if request.env['REMOTE_USER'].eql? uniqname

      # now reset the name
      logger.debug "#{__LINE__}:now switching REMOTE_USER to #{uniqname}."

      logger.debug "resetting remote user"
      # put in session to be available for internal calls to REST api
      session[:remote_user]=uniqname
      request.env['REMOTE_USER']=uniqname

      ## Since container authentication may have been skipped entirely we allow a configurable wait time
      ## before returning which will simulate the delay that could occur with external authentication.
      if !config_hash[:authn_prng].nil?
        wait_sec = config_hash[:authn_prng].rand(config_hash[:authn_wait_min]..config_hash[:authn_wait_max])
        config_hash[:authn_total_wait_time] += wait_sec
        config_hash[:authn_total_stub_calls] += 1
        sleep wait_sec
        logger.debug "#{__LINE__}: wait_sec: #{wait_sec} auth total_wait: #{config_hash[:authn_total_wait_time]} total_calls: #{config_hash[:authn_total_stub_calls]}"
      end

      # things changed so redirect with the new information.
      redirect request.env['REQUEST_URI']
      return
    end

    # See if this user is an admin user.  If necessary
    # get the information from the admin users MCommunity group.
    def admin_user(user)
      ## If no information to check nobody is an admin.

      config_hash = settings.latte_config

      return nil if config_hash[:latte_admin_group].nil?

      config_hash[:admin_members] = LdapCheck.new("group" => config_hash[:latte_admin_group]) if config_hash[:admin_members].nil?
      config_hash[:admin_members].is_user_in_admin_hash user

    end

  end

  ## Add some class level helper methods.
  helpers do

    # This method checks to see if the request is being made only for data for the stated userid.
    # It returns true if the request is NOT permitted.  It is phrased as a veto
    # because this method is only responsible for checking some conditions that might forbid the request.

    def self.vetoRequest(user, request_url)

      # This does the cheap internal checks first since it requires
      # an external call to see if the user is a latte admin.

      # Make sure that someone explicit is making the request.
      return true if user.nil?

      # find any user explicitly mentioned in the url.
      url_user = self.getURLUniqname(request_url)

      # It's fine as long as no user is explicitly named in the url.
      # It can only return information on the current user then.
      return nil if url_user.nil?

      # It is also ok if the user is asking about themselves.
      return nil if url_user.eql? user

      # Only if the user has super powers can they ask about others.
      # The check that they are an admin is delegated to the block passed in.
      # That makes testing much easier and for security related functions
      # testing is critical.

      # This could be shorter but putting the yield in first clause of ternary operator didn't work.
      is_admin = yield user
      veto = is_admin ? nil : true
      logger.warn "vetoed request by #{user} for information url: #{request_url}" unless veto.nil?
      logger.debug "#{__LINE__}: vR: user: #{user} is_admin: #{is_admin} veto: #{veto}"

      veto
    end

    ## extract any uniqname mentioned in this url
    ## Patterns to match are:
    ## /StudentDashboard/courses/ststvii.json
    ## /StudentDashboard/?UNIQNAME=ststvii
    ## /StudentDashboard/terms/ststvii.json
    def self.getURLUniqname(url)

      regex_courses = /courses\/(.*).json/;
      regex_terms = /terms\/(.*).json/;
      regex_UNIQUNAME = /\?UNIQNAME=(.+)/;

      r = regex_courses.match(url)
      return r[1] unless r.nil?

      r = regex_terms.match(url)
      return r[1] unless r.nil?

      r = regex_UNIQUNAME.match(url)
      return r[1] unless r.nil?


      # if didn't match anything then nothing to return.
      nil
    end

  end

  ############ Process requests

  ## Requests are matched and processed in the order matchers appear in the code.  Multiple matches may happen
  ## for a single request if the processing for one match uses pass to let matching code later in the chain process.

  ##### Before clauses are filters that apply before the verb based processing happens.
  ## These before clauses deal with authentication.

  # If permitted take the remote user from the session.  This
  # allows overrides to work for calls from the UI to the REST API.

  before "*" do

    # Need to set session user and remote user.
    # Remote user is the authenticated user. Session user
    # the effective user.  It is kept so that UI calls know who the
    # person of interest is.

    logger.debug "REQUEST: * start processing (user, session, stopwatch)"
    config_hash = settings.latte_config

    ## Get a user name.
    ## if there is no remote_user then set it to default.
    user = request.env['REMOTE_USER']
    # If not set then use the default user
    if user.nil? || user.length == 0
      user = config_hash[:default_user]
    end

    ## Now check to see if allowed to override the user.
    if allow_uniqname_override user

      logger.debug "allowed to override user"
      ## If allowed and there is an user in the session then use that.
      session_user = session[:remote_user]
      if !session_user.nil? && session_user.length > 0
        user = session_user
        logger.debug "#{__LINE__}: authn filter: take user from session: #{user}"
      end
    end

    ## Set that remote user to the computed user.
    logger.debug "remote_user: #{request.env['REMOTE_USER']} computed user: #{user}"
    request.env['REMOTE_USER'] = user

    # store a stopwatch in the session with the current thread id
    msg = Thread.current.to_s + "\t"+request.url.to_s
    sd = Stopwatch.new(msg)
    sd.start
    session[:thread] = sd

    logger.debug "REQUEST: end initial processing"
  end

  ## For testing allow specifying the userid identity to be used on the URL.
  ## This is particularly useful for load testing.  The switch in userid name
  ## only applies to requests for the top level Dashboard page.  This processing
  ## is off by default.
  before '/' do
    ## Check and possibly override the user id
    uniqnameOverride if allow_uniqname_override request.env['REMOTE_USER']
  end

  ## Check that any request for userid data is allowed.
  before "*" do

    # NOTE: the {} block on the end is passed in and used to see if this is an admin user.
    vetoResult = CourseList.vetoRequest(request.env['REMOTE_USER'], request.env['REQUEST_URI']) { admin_user request.env['REMOTE_USER'] }
    logger.debug "REQUEST: * end veto check: [#{vetoResult}]"
    halt 403 if vetoResult == true
  end

  ########### URL ROUTERS ##############
  ## Process the requests based on the URL

  ## If the request isn't for anything specific then return the UI page.
  get '/' do

    config_hash = settings.latte_config
    logger.debug "from (/) settings:"

    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{config_hash[:BASE_DIR]}/UI/index.erb")

    # Make some values available to the UI.
    @server = config_hash[:server]
    @remote_user = request.env['REMOTE_USER']
    @build_time = config_hash[:build_time]
    @build_id = config_hash[:build_id]
    logger.debug "REQUEST: / end root request"

    # Make the strings hash available.  If there is ever a need to
    # select different sets of strings at different times, perhaps by language,
    # it would be trivial to expand the yml file and modify this
    # line to pick amongst different sets of keys.
    @strings = config_hash[:strings]["strings"]

    # This MUST be the last statement since it returns the output text.
    erb idx
  end

  ### Print the API documentation.
  get '/api' do
    @@apidoc
  end

  ## Dump configuration settings to log upon request`
  get '/settings' do
    logger.info "PRINT CURRENT CONFIGURATION"
    config_hash = settings.latte_config
    config_hash.each.sort.each do |key, value|
      logger.info "KEY: #{key}\tVALUE: [#{value}]"
    end
    "settings dumped to log file"
  end

  ### Return json array of the course objects for this user to the UI.  Currently if you don't
  ### specify the json suffix it is an error.
  get '/courses/:userid.?:format?' do |userid, format|
    logger.debug "REQUEST: /courses start"
    termid = params[:TERMID]

    if format && "json".casecmp(format).zero?
      content_type :json

      course_data= dataProviderCourse(userid, termid)
      if "404".casecmp(course_data.meta_status.to_s).zero?
        logger.info "courselist.rb: #{__LINE__}: returning 404 for missing file: userid: #{userid} termid: #{termid}"
        response.status = 404
        return ""
      end
    else
      response.status = 400
      logger.debug "REQUEST: /courses bad format return"
      return "format missing or not supported: [#{format}]"
    end

    course_data.value_as_json
  end

  #### get the terms

  ## ask for terms from the current user.
  get "/terms/?" do
    logger.info "just default terms"
    content_type :json

    termList = dataProviderTerms(request.env['REMOTE_USER'])
    termList.value_as_json
  end

  ## ask for terms for a specific person.
  get "/terms/:userid.?:format?" do |userid, format|

    logger.info "terms"

    userid = request.env['REMOTE_USER'] if userid.nil?

    ## The check for json implies that other format types will fail.
    format = "json" unless (format)

    if format && "json".casecmp(format).zero?
      content_type :json
    else
      response.status = 400
      return "format not supported: [#{format}]"
    end

    termList = dataProviderTerms(userid)
    termList.value_as_json
  end


  ############ check out the esb course call and time the performance.
  check_esb = lambda do

    st = Stopwatch.new("timing of check url")
    st.start
    check_result = dataProviderCheck()
    st.stop

    logger.debug "status: "+check_result.inspect

    if (check_result.meta_status == 200)
      response.status = 200
      maybe_ok = "OK"
    else
      response.status = 500
      maybe_ok = "NOT OK"
    end

    config_hash = settings.latte_config
    return sprintf "status=%s elapsed=%.3f server=%s", maybe_ok, st.summary[0], config_hash[:server]
  end


  get '/check', &check_esb

  ## catch any request not matched and give an error.
  get '*' do
    config_hash = settings.latte_config
    logger.debug "REQUEST: * bad query catch"
    response.status = 400
    return "#{config_hash[:invalid_query_text]}"
  end

  # At end of request print the elapsed time for the request.
  after do
    request_sd = session[:thread]
    request_sd.stop
    logger.info "sd_request: stopwatch: "+request_sd.pretty_summary
  end

  #################### Data provider functions #################

  ## Use the appropriate provider implementation.
  ## This should be implemented to set the desired function upon configuration rather than
  ## to look it up with each request.

  def dataProviderCourse(a, termid)

    config_hash = settings.latte_config
    logger.debug "DataProviderCourse a: #{a} termid: #{termid}"
    logger.debug "data_provider_file_director: #{config_hash[:data_provider_file_directory]}"

    if !config_hash[:data_provider_file_directory].nil?
      return dataProviderFileCourse(a, termid, "#{config_hash[:data_provider_file_directory]}/courses")
    else
      return dataProviderESBCourse(a, termid, config_hash[:security_file], config_hash[:application_name], config_hash[:default_term])
    end

  end

  def dataProviderTerms(uniqname)

    logger.debug "DataProviderTerms uniqname: #{uniqname}"

    config_hash = settings.latte_config

    if !config_hash[:data_provider_file_directory].nil?
      terms = dataProviderFileTerms(uniqname, "#{config_hash[:data_provider_file_directory]}/terms")
    else
      terms = dataProviderESBTerms(uniqname, config_hash[:security_file], config_hash[:application_name])
    end

    terms
  end

  def dataProviderCheck()

    logger.debug "DataProviderCheck"

    config_hash = settings.latte_config

    if !config_hash[:data_provider_file_directory].nil?
      check = dataProviderFileCheck("#{config_hash[:data_provider_file_directory]}/terms")
    else
      check = dataProviderESBCheck(config_hash[:security_file], config_hash[:application_name])
    end

    check
  end

end
