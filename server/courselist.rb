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

  #### NOTE on variables in classes:
  ### @@var is a Class variable: same copy shared by the class and subclasses. Available to class and instance methods.
  ### It is seldom useful as hard to control who can change it.  Not the same as a Java class variable.
  ### @var (in class definition before methods) is a class instance variable and is shared only over the
  ### that class (not children).  Available only to class methods and is private to the class and is similar to a
  ### Java class variable.
  ### When @var referenced in an instance method it is an instance variable and is only available to instance methods.
  ### This is similar to Java instance variable.  However in Sinatra itself we should use the settings capability
  ### instead.

  ### TODO: change from class variables to use settings capability of Sinatra.

  ## Hash to hold the configuration values read in.
  @@l = Hash.new

  ## Location to get the configuration information
  @@config_base ||= '/usr/local/ctools/app/ctools/tl/home'

  # forbid/allow specifying a different user on request url
  @@authn_uniqname_override = false

  ### response to query that is not understood.
  @@invalid_query_text = "invalid query. what U want?"

  ## base directory to ease referencing files in the
  ## build.
  @@BASE_DIR = File.dirname(File.dirname(__FILE__))

  # name of application to use for security information
  @@application_name = "SD-QA"

  # default name of anonymous user
  @@anonymous_user = "anonymous"

  # default location for student dashboard configuration
  @@studentdashboard = "#{@@config_base}/studentdashboard.yml"

  # location for yml file describing the build.
  @@build_file = "#{@@config_base}/build.yml"

  # default location for the security information
  @@security_file = "#{@@config_base}/security.yml"

  # default location for file containing display strings.
  @@strings_file = "#{@@config_base}/strings.yml"

  @@log_file = "server/log/sinatra.log"

  @@default_term = 2010

  # Hold data required if need to put in a wait to simulate authn
  # processing time.
  @@authn_prng = nil
  @@authn_total_wait_time = 0
  @@authn_total_stub_calls = 0

  ## potential list of user with admin priviliges.
  #@@admin = []

  @@admin_members = nil

  ## location of the data files.
  @@data_provider_file_directory = nil

  @@latte_admin_group = nil

  ## api docs
  @@apidoc = <<END

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
    def self.get_local_config_yml(requested_file, default_file)
      if File.exist? requested_file
        file_name = requested_file
      else
        file_name = default_file
      end
      logger.debug "config yml file_name: #{file_name}"
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
    log = File.new(@@log_file, "a+")
    $stdout.reopen(log)
    $stderr.reopen(log)

    $stderr.sync = true
    $stdout.sync = true
  end

  def self.configureStatic
    f = File.dirname(__FILE__)+"/../UI"
    logger.debug("UI files: "+f)
    set :public_folder, f

    ## Set early because it will not change.
    @@server = Socket.gethostname

    # read in yml configuration into a class variable
    @@ls = self.get_local_config_yml(@@studentdashboard, "./server/local/studentdashboard.yml")

    # override default values from configuration file if they are specified.
    @@anonymous_user = @@ls['anonymous_user'] || "anonymous"
    @@invalid_query_text = @@ls['invalid_query_text'] || @@invalid_query_text
    @@authn_uniqname_override = @@ls['authn_uniqname_override'] || @@authn_uniqname_override
    @@application_name = @@ls['application_name'] || @@application_name

    ## See if wait times are set for authn stub wait.
    @@authn_wait_min = @@ls['authn_wait_min'] || 0
    @@authn_wait_max = @@ls['authn_wait_max'] || 0

    #### setup information for providers
    ## configuration information for the file data provider. If not provided then a different
    ## provider will be used.
    @@data_provider_file_directory = @@ls['data_provider_file_directory'] || nil

    @@latte_admin_group = @@ls['latte_admin_group'] || nil
    logger.debug "admin group is: #{@@latte_admin_group}"

    ## If the full path to the provider directory was specified then use it.
    ## Otherwise append what was provided to the local base directory
    if !(@@data_provider_file_directory.nil? || @@data_provider_file_directory.start_with?('/'))
      @@data_provider_file_directory = "#{@@BASE_DIR}/#{@@data_provider_file_directory}"
    end

    ##### setup information for authn override
    #logger.debug "authn_uniqname_override: "+@@authn_uniqname_override.to_s
    ## If there is an authn wait specified then setup a random number generator.
    ## create a variable with a random number generator
    if @@authn_uniqname_override && (@@authn_wait_min > 0 || @@authn_wait_max > 0)
      @@authn_prng = Random.new
      logger.debug "authn wait range is: #{@@authn_wait_min} to #{@@authn_wait_max}"
    end

    @@admin = @@ls['admin'] || []

    @@default_term = @@ls['default_term'] || @@default_term

    # read in yml for the build configuration into a class variable
    begin
      @@build = self.get_local_config_yml(@@build_file, "./server/local/build.yml")
      @@build_time = @@build['time']
      @@build_id = @@build['tag'] || @@build['last_commit']
    rescue
      # The file only needs to be there when a build has been done.  If it isn't there
      # then just use default values.
      @@build = "no build file specified"
      @@build_time = Time.now
      @@build_id = 'development'
    end

    ## read in yml for the strings into a class variable.
    begin
      @@strings = self.get_local_config_yml(@@strings_file, "./server/local/strings.yml")
    rescue
      logger.warn "No strings yml configuration file found"
      @@strings = Hash.new()
    end

  end

  #set :threaded true
  ## make sure logging is available
  configure :test do

    set :logging, Logger::INFO
    #set :logging, Logger::DEBUG

    #configureLogging

    ## look for the UI files in a parallel directory.
    ## this may not be necessary.
    configureStatic
    set :logging, Logger::INFO
    #set :logging, Logger::DEBUG
  end

  ## make sure logging is available in localhost
  configure :production, :development do

    set :logging, Logger::INFO
    #set :logging, Logger::DEBUG
    configureStatic

  end

  ## make sure logging is available to sinatra.log
  configure :development do

    configureLogging

    set :logging, Logger::INFO
    #set :logging, Logger::DEBUG
    configureStatic

  end


  #### Authorization
  # In production the StudentDashboard requires that the user be authenticated.  It verifies this by using the
  # name set in the REMOTE_USER environment variable.  If that variable has no value it will be set to the
  # anonymous user name configured in the studentdashboard.yml file.

  # The Student Dashboard UI makes REST calls back to the application to get data.  These calls are checked to ensure
  # that the call only requests data for the authenticated userid.  The list of users that can override this restriction
  # is supplied by an mcommunity LDAP group named in the studentdashboard.yml file.

  # To ease load testing there are a couple of authentication options that can be configured.  See the
  # studentdashboard.yml file for information on using those.

  ### Add helper instance methods
  helpers do

    def allow_uniqname_override user
      @@authn_uniqname_override == true || admin_user(user)
    end

    ## This will use the UNIQNAME query parameter to set the user considered to be authenticated.  It should
    ## only be invoked in a test setting. It's use can be configured in the studentdashboard.yml file.
    def uniqnameOverride

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
      if !@@authn_prng.nil?
        wait_sec = @@authn_prng.rand(@@authn_wait_min..@@authn_wait_max)
        @@authn_total_wait_time += wait_sec
        @@authn_total_stub_calls += 1
        sleep wait_sec
        logger.debug "#{__LINE__}: wait_sec: #{wait_sec} auth total_wait: #{@@authn_total_wait_time} total_calls: #{@@authn_total_stub_calls}"
      end

      # things changed so redirect with the new information.
      redirect request.env['REQUEST_URI']
      return
    end

    # See if this user is an admin user.  If necessary
    # get the information from the admin users MCommunity group.
    def admin_user(user)
      ## If no information to check nobody is an admin.
      return nil if @@latte_admin_group.nil?

      @@admin_members = LdapCheck.new("group" => @@latte_admin_group) if @@admin_members.nil?
      @@admin_members.is_user_in_admin_hash user

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

    ## Get a user name.
    ## if there is no remote_user then set it to anonymous.
    user = request.env['REMOTE_USER']
    # If not set then use the anonymous user
    if user.nil? || user.length == 0
      user = @@anonymous_user
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

    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{@@BASE_DIR}/UI/index.erb")

    # Make some values available to the UI.
    @server = @@server
    @remote_user = request.env['REMOTE_USER']
    @build_time = @@build_time
    @build_id = @@build_id
    logger.debug "REQUEST: / end root request"

    # Make the strings hash available.  If there is ever a need to
    # select different sets of strings at different times, perhaps by language,
    # it would be trivial to expand the yml file and modify this
    # line to pick amongst different sets of keys.
    @strings = @@strings["strings"]

    # This MUST be the last statement since it returns the output text.
    erb idx
  end

  ### Print the API documentation.
  get '/api' do
    @@apidoc
  end

  ## Dump configuration settings to log upon request`
  get '/settings' do
    logger.info "@@ls: (json) #{@@ls}"
    logger.info "@@build: #{@@build}"
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

     #logger.debug "#{__LINE__}: course_data.value_as_json: "+course_data.value_as_json.inspect
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

  ## catch any request not matched and give an error.
  get '*' do
    logger.debug "REQUEST: * bad query catch"
    response.status = 400
    return "#{@@invalid_query_text}"
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

    logger.debug "DataProviderCourse a: #{a} termid: #{termid}"

    logger.debug "DataProviderCourse a: #{a} termid: #{termid}"
    logger.debug "data_provider_file_director: #{@@data_provider_file_directory}"

    if !@@data_provider_file_directory.nil?
      return dataProviderFileCourse(a, termid, "#{@@data_provider_file_directory}/courses")
    else
      return dataProviderESBCourse(a, termid, @@security_file, @@application_name, @@default_term)
    end

  end

  def dataProviderTerms(uniqname)

    logger.debug "DataProviderTerms uniqname: #{uniqname}"

    if !@@data_provider_file_directory.nil?
      terms = dataProviderFileTerms(uniqname, "#{@@data_provider_file_directory}/terms")
    else
      terms = dataProviderESBTerms(uniqname, @@security_file, @@application_name)
    end

    logger.debug "Dpt: returns: "+terms.inspect

    return terms

  end

end
