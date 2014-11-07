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
require_relative 'WAPI'

include Logging

class CourseList < Sinatra::Base

  ### Class variables

  @@l = Hash.new

  @@config_base ||= '/usr/local/ctools/app/ctools/tl/home'

  # forbid/allow specifying a specific user on request url
  @@authn_uniqname_override = false

  ### response to query that is not understood.
  @@invalid_query_text = "invalid query. what U want?"

  ## base directory to ease referencing files in the war
  @@BASE_DIR = File.dirname(File.dirname(__FILE__))

  @@yml = "HOWDY"

  @@w = nil

  # name of application to use for security information
  @@application_name = "SD-QA"

  # default name of anonymous user
  @@anonymous_user = "anonymous"

  # default location for student dashboard configuration
  #@@studentdashboard = './server/local/studentdashboard.yml'
  @@studentdashboard = "#{@@config_base}/studentdashboard.yml"

  # default location for the security information
  #@@security_file = './server/spec/security.yml'
  @@security_file = "#{@@config_base}/security.yml"

  @@log_file = "server/log/sinatra.log"

  @@default_term = 2010

  # Hold data required if need to wait to simulate authn
  # processing time.
  @@authn_prng = nil
  @@authn_total_wait_time = 0
  @@authn_total_stub_calls = 0

  @@admin = []

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

  ## to force particular logging levels
  # configure :test do
  #   set :logging, Logger::ERROR
  # end
  #
  # configure :development do
  #   set :logging, Logger::DEBUG
  # end
  #
  # configure :production do
  #   set :logging, Logger::INFO
  # end

  ### set configurations
  ### Set configuration values based on the environment.

  # configure :test, :development do
  #   puts "in debug configure"
  # end
  #
  # configure :development do
  #   puts 'in development'
  #   p settings.inspect
  # end


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

  def self.configureYml
    f = File.dirname(__FILE__)+"/../UI"
    logger.debug("UI files: "+f)
    set :public_folder, f

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


    logger.debug "authn_uniqname_override: "+@@authn_uniqname_override.to_s
    ## If there is an authn wait specified then setup a random number generator.
    ## create a variable with a random number generator
    if @@authn_uniqname_override && (@@authn_wait_min > 0 || @@authn_wait_max > 0)
      @@authn_prng = Random.new
      logger.debug "authn wait range is: #{@@authn_wait_min} to #{@@authn_wait_max}"
    end

    @@admin = @@ls['admin'] || []

    @@default_term = @@ls['default_term'] || @@default_term
    #puts "admin list: "
    #p @@admin


  end

  ## make sure logging is available
  configure :test do

    set :logging, Logger::DEBUG

    #configureLogging

    ## look for the UI files in a parallel directory.
    ## this may not be necessary.
    configureYml

  end

  ## make sure logging is available
  configure :production, :development do

    set :logging, Logger::DEBUG

    configureLogging

    configureYml

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

      logger.debug "#{__LINE__}:vetoRequest: userid: [#{user}] request_url: [#{request_url}]"
      #logger.debug "#{__LINE__}: vetoRequest: "+caller.join("\n")

      # Make sure that someone explicit is making the request.
      return true if user.nil?

      # admin users can request for everybody.
      if @@admin.include? user
        logger.debug "#{__LINE__}:vetoRequest: found admin userid: #{user}"
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

  ## Make sure we have a remote "authenticated" userid.  This is useful for testing when
  ## not running in a container.
  ## Take the userid from the REMOTE_USER variable
  ## If not there check session.
  ## if not there default to anonymous userid
  before "*" do
    #logger.debug "#{__LINE__}: authn filter: request.env" + request.env.inspect
    logger.debug "#{__LINE__}: host: "+request.host

    ## try setting userid from request remote_user
    user = request.env['REMOTE_USER']
    logger.debug "before *: #{user}"

    ## if not there try setting from session remote userid
    if user.nil? || user.length == 0
      logger.debug "#{__LINE__}: authn filter: no REMOTE_USER try session"
      user = session[:remote_user]
      request.env['REMOTE_USER'] = user
    end

    ## If still not set use the anonymous userid
    logger.debug "#{__LINE__}: authn filter: userid after check session: #{user}"
    if user.nil? || user.length == 0
      request.env['REMOTE_USER'] = @@anonymous_user
    end
    #logger.debug "before * first: request.env" + request.env.inspect
  end

  ## For testing allow specifying the userid identity to be used on the URL.
  ## This is particularly useful for load testing.  The switch in userid name
  ## only applies to requests for the top level Dashboard page.  This processing
  ## is off by default.
  before '/' do

    ## Allow overriding the uniqname during testing
    logger.debug "#{__LINE__}:authn_uniqname_override: "+@@authn_uniqname_override.to_s
    uniqnameOverride if @@authn_uniqname_override == true

  end

  ## Check that any request for userid data is either for data for the authenticated userid
  ## or the authenticated userid is listed as a special admin userid.
  before "*" do
    ## Make sure people only ask about themselves (or are privileged)
    logger.debug "#{__LINE__}:before *: check veto"
    vetoResult = CourseList.vetoRequest request.env['REMOTE_USER'], request.env['REQUEST_URI']
    logger.debug "vetoResult: "+vetoResult.to_s
    halt 401 if vetoResult == true
  end

  ########### URL ROUTERS ##############
  ## Process the requests based on the URL

  ## If the request isn't for anything specific then return the UI page.
  get '/' do
    logger.debug "#{__LINE__}:in top page"
    # logger.debug "top page: request.env" + request.env.inspect
    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{@@BASE_DIR}/UI/index.erb")


    # get some value for remote_user even if it isn't in the request.
    # the value of @remote_user will be available in the erb UI template.
    logger.debug "#{__LINE__}:top page: required now after making sure there is a userid?"
    @remote_user = request.env['REMOTE_USER']
    @remote_user = @@anonymous_user if @remote_user.nil? || @remote_user.empty?
    @remote_user = request.env['REMOTE_USER'] || @@anonymous_user

    logger.info "#{__LINE__}:REMOTE_USER: [#{@remote_user}]"
    #logger.debug "top page: idx: #{idx}"
    erb idx
  end

  ### send the documentation
  get '/api' do
    @@apidoc
  end

  ## dump settings to log upon request`
  get '/settings' do
    logger.info "@@ls: (json) #{@@ls}"
    "settings dumped to log file"
  end

  ### Return json array of the course objects for this user.  Currently if you don't
  ### specify the json suffix it is an error.
  get '/courses/:userid.?:format?' do |userid, format|
    logger.info "#{__LINE__}: userid: #{:userid} format: #{:format}"
    logger.info "#{__LINE__}:courses: params: "+params.inspect
    termid = params[:TERMID]

    logger.info "#{__LINE__}:termid:: #{termid}"

    if format && "json".casecmp(format).zero?
      content_type :json
      courseDataForX = CourseDataProvider(userid,termid)
      if "404".casecmp(courseDataForX).zero?
        logger.debug "#{__LINE__}: returning 404 for missing file"
        response.status = 404
        return ""
      end

      courseDataForXJson = JSON.parse courseDataForX

      # return data as json
      courseDataForXJson.to_json

    else
      response.status = 400
      return "format missing or not supported: [#{format}]"
    end
  end

  # get '/courses/:userid.?:format?' do |userid, format|
  #   logger.info "#{__LINE__}:courses/:userid: #{userid} format: #{format}"
  #   logger.info "#{__LINE__}:params:"+params.inspect
  #   if format && "json".casecmp(format).zero?
  #     content_type :json
  #     courseDataForX = CourseDataProvider(userid)
  #     #logger.info "courseData from provider #{courseDataForX}"
  #     if "404".casecmp(courseDataForX).zero?
  #       logger.debug "#{__LINE__}: returning 404 for missing file"
  #       response.status = 404
  #       return ""
  #     end
  #
  #     # parse return value as json so it is converted from string
  #     # format.
  #     courseDataForXJson = JSON.parse courseDataForX
  #     #logger.info "courseData as json #{courseDataForXJson}"
  #
  #     # return data as json
  #     courseDataForXJson.to_json
  #
  #   else
  #     response.status = 400
  #     return "format missing or not supported: [#{format}]"
  #   end
  # end

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





  ### Grab the desired data provider.
  ### Need to make the provider selection settable via properties.
  def CourseDataProvider(a,termid)
    #return CourseDataProviderStatic(a,termid)
    logger.debug "CourseDataProvider a: #{a} termid: #{termid}"
    #return CourseDataProviderFile(a,termid)
    return CourseDataProviderESB(a,termid)
  end

  ###### File provider ################
  ### Return the data from a matching file.  The file must be in a sub-directory
  ### under the directory specified by the property data_file_dir.
  ### The sub-directory will be the name of the type of data requested (e.g. courses)
  ### The name of the file must match the rest of the URL.
  ### E.g. localhost:3000/courses/abba.json would map to a file named abba.json in the 
  ### courses sub-directory under, in this case, the test-files directory.

  def CourseDataProviderFile(a,termid)
    logger.debug "data provider is CourseDataProviderFile.\n"

    dataFile = "#{@@BASE_DIR}/"+@@ls['data_file_dir']+"/"+@@ls['data_file_type']+"/#{a}.json"
    logger.debug "data file string: "+dataFile

    if File.exists?(dataFile)
      logger.debug("file exists: #{dataFile}")
      classes = File.read(dataFile)
    else
      logger.debug("file does not exist: #{dataFile}")
      classes = "404"
    end

    logger.debug("returning: "+classes)
    return classes
  end

  def CourseDataProviderESB(uniqname,termid)
    logger.info "data provider is CourseDataProviderESB.\n"
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = initESB
    end



    if termid.nil? || termid.length == 0
      logger.debug "defaulting term to #{@@default_term}"
      termid = @@default_term
    end

    url = "/Students/#{uniqname}/Terms/#{termid}/Schedule"

    logger.debug("ESB: url: "+url)
    logger.debug("@@w: "+@@w.to_s)

    classes = @@w.get_request(url)
    #   logger.debug("CL: ESB returns: "+classes)
    r = JSON.parse(classes)['getMyClsScheduleResponse']['RegisteredClasses']
    r2 = JSON.generate r
    # logger.debug "Course data provider returns: "+r2
    return r2
  end

  def initESB
    logger.info "initESB"

    logger.info("security_file: "+@@security_file.to_s)
    requested_file = @@security_file

    default_security_file = './server/local/security.yml'

    if File.exist? requested_file
      file_name = requested_file
    else
      file_name = default_security_file
    end
    logger.debug "security file_name: #{file_name}"
    @@yml = YAML.load_file(file_name)

    app_name=@@application_name
    setup_WAPI(app_name)
  end

  def setup_WAPI(app_name)
    logger.info "use ESB application: #{app_name}"
    application = @@yml[app_name]
    @@w = WAPI.new application
  end

  ##### Trivial static data provider
  def CourseDataProviderStatic(a)
    logger.debug("data provider is CourseDataProviderStatic")
    classJson =
        [
            {:title => "English 323",
             :subtitle => "Austen and her contemporaries and #{a}",
             :location => "canvas",
             :link => "google.com",
             :instructor => "me: #{a}",
             :instructor_email => "howdy ho"
            },
            {:title => "German 323",
             :subtitle => "Beeoven and her contemporaries and #{a}",
             :location => "ctools",
             :link => "google.com",
             :instructor => "you: Mozarty",
             :instructor_email => "howdy haw"
            },
            {:title => "Philosophy 323",
             :subtitle => "Everybody and nobody at all along with you: #{a}",
             :location => "none",
             :link => "google.com",
             :instructor => "Life",
             :instructor_email => "google@google.goo"
            }
        ]
    return classJson
  end


end

__END__

###### inline templates are here.

### API documentation as slim template.
@@ apidocA
   h1 This is the API documentation
   h2 '/api' will return api documentation.
   h2 '/courses/{userid}.json' will return course objects for this userid.

