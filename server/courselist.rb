## Making required modules available
require File.expand_path(File.dirname(__FILE__) + '/data_provider_esb.rb')
require File.expand_path(File.dirname(__FILE__) + '/data_provider_file.rb')

### Simple rest server for SD data
### This version will also server up the HTML page if no
### specific page is requested.

### Configuration will be read in from /usr/local/studentdashboard/studentdashboard.yml if available
### or from ./server/local/studentdashboard.yml in the build if necessary.

### Sinatra is a DSL (domain specific language) for working with HTTP requests.

require 'sinatra'
require 'json'
require 'slim'
require 'yaml'
require_relative 'stopwatch'
require_relative 'WAPI'
require_relative 'WAPI_result_wrapper'

include Logging

class CourseList < Sinatra::Base
  ## mixin the providers functionality.
  include DataProviderESB
  include DataProviderFile

  #### NOTE on variables in classes:
  ### @@var is a Class variable: same copy shared by the class and subclasses. Available to class and instance methods.
  ### << Seldom useful as hard to control who can change it.  Not the same as a Java class variable.
  ### @var (in class definition before methods) is a class instance variable and is shared only over the
  ### that class (not children).  Available only to class methods and is private to the class.
  ### << Similar to Java class variable
  ### @var referenced in an instance method. Is an instance variable and is only available to instance methods.
  ### << Similar to Java instance variable.

  ### TODO: change from class variables to class instance variables.

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

  @@log_file = "server/log/sinatra.log"

  @@default_term = 2010

  # Hold data required if need to put in a wait to simulate authn
  # processing time.
  @@authn_prng = nil
  @@authn_total_wait_time = 0
  @@authn_total_stub_calls = 0

  ## potential list of user with admin priviliges.
  @@admin = []

  ## location of the data files.
  @@data_provider_file_directory = nil


  ## api docs
  @@apidoc = <<END

<p/>
HOST://api - this documentation.
 <p/>
HOST://courses/{uniqname}.json - An array of (fake) course data for this person.  The
query parameter of TERMID=<termid> is required.
 <p/>
HOST://terms - returns a list of terms in format described below.
<p/>
HOST://settings - dump data to the log.
<p/>
It could use improvement so feel free to help!  Please update this section with any 
API changes.

END

  ## This method will return the contents of the requested (or default) configuration file.

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

    ## If the full path to the provider directory was specified then use it.
    ## Otherwise append what was provided to the local base directory
    if !(@@data_provider_file_directory.nil? || @@data_provider_file_directory.start_with?('/'))
      @@data_provider_file_directory = "#{@@BASE_DIR}/#{@@data_provider_file_directory}"
    end

    ##### setup information for authn override
    logger.debug "authn_uniqname_override: "+@@authn_uniqname_override.to_s
    ## If there is an authn wait specified then setup a random number generator.
    ## create a variable with a random number generator
    if @@authn_uniqname_override && (@@authn_wait_min > 0 || @@authn_wait_max > 0)
      @@authn_prng = Random.new
      logger.debug "authn wait range is: #{@@authn_wait_min} to #{@@authn_wait_max}"
    end

    @@admin = @@ls['admin'] || []

    @@default_term = @@ls['default_term'] || @@default_term

    # read in yml configuration into a class variable
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

  end

  #set :threaded true
  ## make sure logging is available
  configure :test do

    #set :logging, Logger::DEBUG
    set :logging, Logger::INFO

    #configureLogging

    ## look for the UI files in a parallel directory.
    ## this may not be necessary.
    configureStatic
    set :logging, Logger::INFO
  end

  ## make sure logging is available in localhost
  configure :production, :development do

    set :logging, Logger::INFO
    configureStatic

  end

  ## make sure logging is available to sinatra.log
  configure :development do

    configureLogging
    set :logging, Logger::INFO
    configureStatic

  end



  #### Authorization
  # StudentDashboard requires that the user be authenticated.  It verifies this by using the name set in the
  # REMOTE_USER environment variable.  If that variable has no value it will be set to the anonymous user name
  # from the studentdashboard.yml file.  This is convenient for testing.

  # The Student Dashboard UI makes REST calls to the application to get data.  These calls are checked to ensure
  # that the call only requests data for the authenticated userid.  A list of users that can override this restriction
  # can be added to the yml configuration file.

  # To ease load testing there are a couple of authentication options that can be configured.  See the
  # studentdashboard.yml file for information on using those.

  ### Add helper to deal with stubbing the authentication for testing purposes.
  helpers do
    def uniqnameOverride
      # If permitted ignore authentication checks and read the name to be used as the authenticated user
      # from the URL.  This can only be invoked in a test setting.

      # See if there is a candidate to use as authenticated userid name.
      uniqname = params['UNIQNAME']
      logger.debug "#{__LINE__}:found uniqname: #{uniqname}"

      # don't reset userid if don't have a name to reset it to.
      pass if uniqname.nil? || uniqname.length == 0

      # don't reset if not necessary.  This prevents infinite loops.
      pass if request.env['REMOTE_USER'].eql? uniqname

      # now reset the name
      logger.debug "#{__LINE__}:now switching REMOTE_USER to #{uniqname}."

      # put in session to be available for internal calls to REST api
      session[:remote_user]=uniqname
      request.env['REMOTE_USER']=uniqname

      ## Since container authentication may have been skipped entirely allow a configurable wait time
      ## before returning to simulate the delay that could occur with external authentication.
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
  end


  ## add helper to deal with checking that someone only asks about themselves.
  helpers do

    # This method checks to see if the request is being made only for data for the stated userid.
    # It returns true if the request is NOT permitted.  It is phrased as a veto
    # because this method isn't responsible for checking all conditions that might forbid the request.

    def self.vetoRequest(user, request_url)

      #logger.debug "#{__LINE__}:vetoRequest: userid: [#{user}] request_url: [#{request_url}]"
      #logger.debug "#{__LINE__}: vetoRequest: "+caller.join("\n")

      # Make sure that someone explicit is making the request.
      return true if user.nil?

      # admin users can request for everybody.
      if @@admin.include? user
        # logger.debug "#{__LINE__}:vetoRequest: found admin userid: #{user}"
        return nil
      end

      ## We are only interested in URLS that look like this.
      areg = (/courses\/(.*).json$/)

      # get the userid for which the data is requested.
      url_user = areg.match(request_url)

      # Don't veto if don't recognise the URL.
      return nil if url_user.nil?

      # Make sure the request is for the authenticated userid.
      should_veto = url_user[1] != user

      logger.debug "#{__LINE__}: vetoRequest: should_veto: #{should_veto}"
      return should_veto

    end
  end

  #### Process requests

  ## Requests are matched and processed in the order matchers appear in the code.  Multiple matches may happen
  ## for a single request if the processing for one match uses pass to let matching code later in the chain process.

  ##### Before clauses are filters that apply before the verb based processing happens.
  ## These before clauses deal with authentication.

  # If permitted take the remote user from the session.  This
  # allows overrides to work for calls from the UI to the REST API.

  before "*" do

    ## if there is no remote_user then set it to anonymous.
    user = request.env['REMOTE_USER']
    #logger.debug "#{__LINE__}: authn filter: starting userid: #{user}"

    # If not set then use the anonymous user
    if user.nil? || user.length == 0
      user = @@anonymous_user
    end

    ## Now check to see if allowed to override the user.
    if @@authn_uniqname_override == true

      ## If allowed and there is an user in the session then use that.
      session_user = session[:remote_user]
      if !session_user.nil? && session_user.length > 0
        user = session_user
        #    logger.debug "#{__LINE__}: authn filter: take user from session: #{user}"
      end
    end

    ## Set that remote user.
    request.env['REMOTE_USER'] = user

    # store a stopwatch in the session with the current thread id
    msg = Thread.current.to_s + "\t"+request.url.to_s
    sd = Stopwatch.new(msg)
    sd.start
    session[:thread] = sd

    ## add the stopwatch to a session and print
  end

  ## For testing allow specifying the userid identity to be used on the URL.
  ## This is particularly useful for load testing.  The switch in userid name
  ## only applies to requests for the top level Dashboard page.  This processing
  ## is off by default.
  before '/' do

    ## Check and possibly override the user id
    logger.debug "#{__LINE__}:authn_uniqname_override: "+@@authn_uniqname_override.to_s
    uniqnameOverride if @@authn_uniqname_override == true

  end

  ## Check that any request for userid data is either for data for the authenticated userid
  ## or the authenticated userid is listed as a special admin userid.
  before "*" do
    ## Make sure people only ask about themselves (or are privileged)
    vetoResult = CourseList.vetoRequest request.env['REMOTE_USER'], request.env['REQUEST_URI']
    logger.debug "vetoResult: "+vetoResult.to_s
    halt 403 if vetoResult == true
  end

  ########### URL ROUTERS ##############
  ## Process the requests based on the URL

  ## If the request isn't for anything specific then return the UI page.
  get '/' do
    # logger.debug "top page: request.env" + request.env.inspect
    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{@@BASE_DIR}/UI/index.erb")

    # Make remote user available to the UI along with build information.
    # The server name was set earlier
    # Put the global into the instance variable so that it will get down into
    # the render html.
    @server = @@server

    @remote_user = request.env['REMOTE_USER']
    @build_time = @@build_time
    @build_id = @@build_id

    erb idx
  end

  ### send the documentation
  get '/api' do
    @@apidoc
  end

  ## dump settings to log upon request`
  get '/settings' do
    puts "settings: "+@@ls.inspect
    logger.info "@@ls: (json) #{@@ls}"
    logger.info "@@build: #{@@build}"
    "settings dumped to log file"
  end

  ### Return json array of the course objects for this user.  Currently if you don't
  ### specify the json suffix it is an error.
  get '/courses/:userid.?:format?' do |userid, format|
    termid = params[:TERMID]

#    logger.debug "#{__LINE__}:termid:: #{termid}"

    if format && "json".casecmp(format).zero?
      content_type :json

      courseDataForX = DataProviderCourse(userid, termid)
      if "404".casecmp(courseDataForX.meta_status.to_s).zero?
        logger.info "#{__LINE__}: returning 404 for missing file"
        response.status = 404
        return ""
      end
    else
      response.status = 400
      return "format missing or not supported: [#{format}]"
    end
#logger.debug "#{__LINE__}: courseDataForX.value_as_json: "+courseDataForX.value_as_json.inspect
    courseDataForX.value_as_json
  end

  ### Return json array of the current objects.
  get '/terms' do
    logger.info "terms"
    content_type :json
    termList = termProviderStatic
    termList.to_json
  end

  ## catch any request not matched and give an error.
  get '*' do
    response.status = 400
    return "#{@@invalid_query_text}"
  end

  after do
  request_sd = session[:thread]
  request_sd.stop
  logger.info "sd_request: stopwatch: "+request_sd.pretty_summary
end

  #################### Data provider functions #################

  ##### Term providers
  ## provide a static set of terms
  #{"getMyRegTermsResponse":{"@schemaLocation":"http:\/\/mais.he.umich.edu\/schemas\/getMyRegTermsResponse.v1 http:\/\/csqa9ib.dsc.umich.edu\/PSIGW\/PeopleSoftServiceListeningConnector\/getMyRegTermsResponse.v1.xsd","Term":{"TermCode":"2010","TermDescr":"Fall 2014","TermShortDescr":"FA 2014"}}}
  #terms = "{Term":{"TermCode":"2010","TermDescr":"Fall 2014","TermShortDescr":"FA 2014"}}
  #Format from TLPORTAL-106
  #- term(str)
  #- year(str)
  #- term-id(str)
  #- current-term(bool)
  # [
  #     {
  #         "term": "Fall",
  #     "year": "2014",
  #     "term_id": "2010",
  #     "current_term": true
  # },
  #     {
  #         "term": "Winter",
  #     "year": "2015",
  #     "term_id": "2030",
  #     "current_term": false
  # }
  # ]

  # value returned from ESB
  #Hash[:TermCode => "2020", :TermDescr => "Mine 2014", :TermShortDesc => "NaNa 2014"]
  # desired format
  #  {"term": "Fall", "year": "2014", "term_id": "2010", "current_term": true}
  ### mapping from ESB value
  # term from first part of TermDescr (without year and trimming spaces)
  # year from last part of TermDescr (4 integers at end of string)
  # term_id from TermCode
  # current_term is set as the first term in the list for the time being.

  def termProviderStatic
    termList = Array.new
    termList << Hash[:term => "Fall", :year => "2014", :term_id => "2010", current_term: true]
    termList << Hash[:term => "Winterish", :year => "2014", :term_id => "2020", current_term: false]
  end


  ## Grab the desired data provider.
  ## Would be good to hide the extra parameters

  def DataProviderCourse(a, termid)

    logger.debug "DataProviderCourse a: #{a} termid: #{termid}"


    if !@@data_provider_file_directory.nil?
      return DataProviderFileCourse(a, termid, @@data_provider_file_directory)
    else
      return DataProviderESBCourse(a, termid, @@security_file, @@application_name, @@default_term)
    end

  end

end
