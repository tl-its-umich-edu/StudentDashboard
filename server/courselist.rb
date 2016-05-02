## These lines make the required modules available.

### Configuration will be read in from /usr/local/ctools/app/ctools/tl/home/studentdashboard.yml file if available
### or from ./server/local/studentdashboard.yml in the build if necessary.

### Sinatra is a DSL (domain specific language) for working with HTTP requests.

require 'sinatra'
require 'json'
require 'slim'
require 'yaml'
require 'tilt/erb'
require 'erb'

require_relative 'stopwatch'
require_relative 'WAPI'
require_relative 'data_provider'
require_relative 'WAPI_result_wrapper'
require_relative 'ldap_check'
require_relative 'external_resources_file'
require_relative 'OptionsParse'
require_relative 'Logging'

#include Logging
extend Logging
include ERB::Util

class CourseList < Sinatra::Base
  include DataProvider

  # To store persistent configuration values in Sinatra requires using the settings feature.
  # To make all our configuration values available we store a hash of all the
  # configuration values using settings and access the values through that hash.

  ## These configuration values are defined with default values but can, and
  ## often are, overridden by values in the configuration yml files.  The default
  ## values are designed to be useful for development.

  ## Reading configuration files and overriding values is currently clunky and may be addressed in a
  ## separate jira.

  #### Setup default values.

  ## Setup hash to hold dynamic / environment objects.
  dynamic_hash = Hash.new
  set :dynamic_config, dynamic_hash

  ## Will store static configuration settings in this hash.
  config_hash = Hash.new

  # Will store the hash in the Sinatra settings object so it is available
  # where needed.
  set :latte_config, config_hash

  ## Allow override of the location of the studentdashboard.yml file.
  if ENV['LATTE_OPTS'] then
    env_options = OptionsParse.parseEnvironment('LATTE_OPTS')

    unless env_options.config_base.nil?
      config_base = env_options.config_base
    end
  end

  # Location to find the configuration files if not specified by an environment variable.
  # This can't be overridden by value in a configuration file because is the location
  # of the configuration file.
  config_base ||= '/usr/local/ctools/app/ctools/tl/home'

  # forbid/allow specifying a different user on request url
  config_hash[:authn_uniqname_override] = false

  ### response to query that is not understood.
  config_hash[:invalid_query_text] = "invalid query. what U want?"

  ## base directory to ease referencing files in the
  ## build.
  config_hash[:BASE_DIR] = File.dirname(File.dirname(__FILE__))

  # name of application to use for ESB information
  #config_hash[:mpathways_application_name] = "SD-QA"

  # name of application to use for CTools HTTP direct information
  #config_hash[:ctools_http_application_name] = "CTQA-DIRECT"

  # name of application to use for canvas esb
  #config_hash[:canvas_esb_application_name] = "CANVAS-TL-QA"

  # default name of default user
  config_hash[:default_user] = "default"

  # default location for student dashboard configuration
  config_hash[:studentdashboard] = "#{config_base}/studentdashboard.yml"

  # location for yml file describing the build.
  config_hash[:build_file] = "./server/local/build.yml"

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
  config_hash[:data_provider_file_uniqname] = nil

  config_hash[:latte_admin_group] = nil

  # initial default
  config_hash[:use_log_level] = "DEBUG"

  # configuration settings for the canvas calender_events api call
  # Someday make the string vs symbol keys consistent everywhere.
  config_hash[:canvas_calendar_events] = {
      'max_results_per_page' => 100,
      'previous_days' => 7,
      'next_days' => 8
  }

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
HOST://external - list directories with available external static resources.
<p/>
HOST://external/<directory> - list available files within this directory.
<p/>
HOST://external/<directory>/<file> - return an available static file.
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
        logger.fatal "#{self.class.to_s}:#{__method__}:#{__LINE__}: can not find requested or default configuration file: [#{requested_file}] or [#{default_file}]" if required
        return nil
      end

      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: local_config_yml: found file: [#{file_name}]"
      YAML.load_file(file_name)

    end

    # This has it's own separate unit test file as the data can be complicated.
    # get list of hash values for this key in nested hashes in mixed array / hash data structure.
    def self.getValuesForKey(key, obj)
      values = [] # local to this invocation.
      case obj
        when Array # check out the elements in the array
          values = obj.flat_map { |o| self.getValuesForKey(key, o) }
        when Hash # remember value if key is right, for other keys recurse on value.
          obj.each_pair { |k, v| values.push(k === key ? v : self.getValuesForKey(key, v)) }
          values.flatten! # get rid of any nested arrays
      end
      values
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
                       logger.error("#{self.class.to_s}:#{__method__}:#{__LINE__}: log level requested is not understood: #{use_log_level}");
                       starting_log_level
                   end

    set :logging, logger.level

  end


  ##### Some configuration is static and the values are specified in configuration files
  ##### Other configuration is dynamic and needs to be created on the fly.  E.g. provider
  ##### implementations.  There are two startup methods for these.  "configureStatic" deals
  ##### with reading configuration properties.  "configureDynamic" deals with creation of
  ##### configured objects.


  def self.configureStatic

    f = File.dirname(__FILE__)+"/../UI"
    set :public_folder, f

    config_hash = settings.latte_config

    ## Set early because it will not change.
    config_hash[:server] = Socket.gethostname

    ## Reading configuration files and overriding values is currently clunky and may be addressed in a
    ## separate jira.

    # read in yml configuration into a class variable
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: requested configuration file is: #{config_hash[:studentdashboard]}"
    external_config = self.get_local_config_yml(config_hash[:studentdashboard], "./server/local/studentdashboard.yml", true)

    config_hash[:use_log_level] = external_config['use_log_level'] || "INFO"

    setLoggingLevel(config_hash[:use_log_level])

    config_hash[:debug_max_length] = external_config['debug_max_length'] || 50

    # override default values from configuration file if they are specified.
    config_hash[:default_user] = external_config['default_user'] || "anonymous"
    config_hash[:invalid_query_text] = external_config['invalid_query_text'] || config_hash[:invalid_query_text]
    config_hash[:authn_uniqname_override] = external_config['authn_uniqname_override'] || config_hash[:authn_uniqname_override]
    config_hash[:mpathways_application_name] = external_config['mpathways_application_name'] || config_hash[:mpathways_application_name]
    config_hash[:ctools_http_application_name] = external_config['ctools_http_application_name'] || config_hash[:ctools_http_application_name]
    config_hash[:canvas_esb_application_name] = external_config['canvas_esb_application_name'] || config_hash[:canvas_esb_application_name]

    # get the information for this application into the config hash under the explicit application name
    config_hash[config_hash[:canvas_esb_application_name]] = external_config[config_hash[:canvas_esb_application_name]]
    config_hash[config_hash[:ctools_http_application_name]] = external_config[config_hash[:ctools_http_application_name]]

    ## See if wait times are set for authn stub wait.
    config_hash[:authn_wait_min] = external_config['authn_wait_min'] || 0
    config_hash[:authn_wait_max] = external_config['authn_wait_max'] || 0

    #### setup information for providers
    ## configuration information for the file data provider. If this is not set then a different
    ## provider will be used.
    config_hash[:data_provider_file_directory] = external_config['data_provider_file_directory'] || nil
    config_hash[:data_provider_file_uniqname] = external_config['data_provider_file_uniqname'] || nil

    ## If the full path to the provider directory was specified then use it.
    ## Otherwise append what was provided to the local base directory
    if !(config_hash[:data_provider_file_directory].nil? || config_hash[:data_provider_file_directory].start_with?('/'))
      config_hash[:data_provider_file_directory] = "#{config_hash[:BASE_DIR]}/#{config_hash[:data_provider_file_directory]}"
    end

    ## Default the external resources to be the test values in the build if not otherwise specified.
    config_hash[:external_resources_file_directory] = external_config['external_resources_file_directory'] || nil
    config_hash[:external_resources_valid_directories] = external_config['external_resources_valid_directories'] || nil

    # default for the group controlling admin membership.
    config_hash[:latte_admin_group] = external_config['latte_admin_group'] || nil

    ##### setup information for authn override
    ## If there is an authn wait specified then setup a random number generator.
    ## create a variable with a random number generator
    if config_hash[:authn_uniqname_override] && (config_hash[:authn_wait_min] > 0 || config_hash[:authn_wait_max] > 0)
      config_hash[:authn_prng] = Random.new
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: authn wait range is: #{config_hash[:authn_wait_min]} to #{config_hash[:authn_wait_max]}"
    end

    config_hash[:admin] = external_config['admin'] || []

    config_hash[:default_term] = external_config['default_term'] || config_hash[:default_term]

    config_hash[:canvas_calendar_events] = external_config['canvas_calendar_events'] || config_hash[:canvas_calendar_events]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: config_hash: canvas_calendar_events: #{config_hash[:canvas_calendar_events]}"

    # set containing directory for (most of the) erb files
    set :views, "#{config_hash[:BASE_DIR]}/UI/views"

    # Read in yml for the build configuration into a class variable if available.
    begin
      config_hash[:build_full] = self.get_local_config_yml(config_hash[:build_file], "./server/local/build.yml", false)
      config_hash[:build] = config_hash[:build_full][:build]
      config_hash[:build_time] = config_hash[:build]['time']
      config_hash[:build_id] = config_hash[:build]['tag'] || config_hash[:build]['last_commit']
    rescue
      # Use default values.
      config_hash[:build] = "no build file specified"
      config_hash[:build_time] = Time.now
      config_hash[:build_id] = 'development'
    end

    ## read in yml for the strings into a class variable.
    begin
      config_hash[:strings] = self.get_local_config_yml(config_hash[:strings_file], "./server/local/strings.yml", true)
    rescue
      logger.warn "#{self.class.to_s}:#{__method__}:#{__LINE__}: No strings yml configuration file found"
      config_hash[:strings] = Hash.new()
    end

  end

  ################################
  ## Some configuration requires creating long lived object instances.
  ## Those are created here.  The Dashboard static properties will have been read in by this point.
  def self.configureDynamic
    config_hash = settings.latte_config
    dynamic_hash = settings.dynamic_config

    if config_hash[:external_resources_file_directory].nil?
      config_hash[:external_resources_file_directory] = config_hash[:BASE_DIR]+"/server/test-files/resources"
    end

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: external resource directory final: "+config_hash[:external_resources_file_directory]
    resources_dir = config_hash[:external_resources_file_directory]
    ext_resources = ExternalResourcesFile.new(resources_dir)
    dynamic_hash[:external_resources] = ext_resources
  end

  ## make sure logging is available
  configure :test do

    configureStatic
    configureDynamic

  end

  ## make sure logging is available in localhost
  configure :production, :development do

    configureStatic
    configureDynamic

  end

  ## make sure logging is available to sinatra.log
  configure :development do

    configureLogging

    configureStatic
    configureDynamic

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

    # truncate limit a string to specific length.  Default length to 50
    def self.limit_msg(msg)
       config_hash = settings.latte_config
       use_length = config_hash[:debug_max_length] || 50
       msg[0..use_length] + (msg.length < use_length ? '' : '....')
     end


    def allow_uniqname_override user
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: admin_user(#{user}): #{admin_user(user)}"
      settings.latte_config[:authn_uniqname_override] == true || admin_user(user)
    end

    ## This will use the UNIQNAME query parameter to set the user considered to be authenticated.  It should
    ## only be invoked in a test setting. It's use can be configured in the studentdashboard.yml file.
    def uniqnameOverride

      config_hash = settings.latte_config

      # See if there is a candidate to use as authenticated userid name.
      uniqname = CourseList.safe_html_escape(params['UNIQNAME'])
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: uniqname: #{uniqname}"

      # don't reset userid if don't have a name to reset it to.
      pass if uniqname.nil? || uniqname.length == 0

      # don't reset if not necessary.  This prevents infinite loops.
      pass if request.env['REMOTE_USER'].eql? uniqname

      # now reset the name
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: now switching REMOTE_USER to [#{uniqname}]."

      # put in session to be available for internal calls to REST api
      #uniqname has been escaped above
      session[:remote_user]=uniqname
      request.env['REMOTE_USER']=uniqname

      ## Since container authentication may have been skipped entirely we allow a configurable wait time
      ## before returning which will simulate the delay that could occur with external authentication.
      if !config_hash[:authn_prng].nil?
        wait_sec = config_hash[:authn_prng].rand(config_hash[:authn_wait_min]..config_hash[:authn_wait_max])
        config_hash[:authn_total_wait_time] += wait_sec
        config_hash[:authn_total_stub_calls] += 1
        sleep wait_sec
        logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: wait_sec: #{wait_sec} auth total_wait: #{config_hash[:authn_total_wait_time]} total_calls: #{config_hash[:authn_total_stub_calls]}"
      end

      # things changed so redirect with the new information.
      redirect request.env['REQUEST_URI']
      return
    end

    # See if this user is an admin user.  If necessary
    # get the information from the admin users MCommunity group.

    def admin_user(user)
      config_hash = settings.latte_config
      # nobody is admin if there is no admin group.
      return nil if config_hash[:latte_admin_group].nil?

      config_hash[:admin_members] = LdapCheck.new("group" => config_hash[:latte_admin_group]) if config_hash[:admin_members].nil?
      config_hash[:admin_members].is_user_in_admin_hash user

    end

    #### Return status information in arrays of data by topic
    def build_info
      build_configuration_file = 'server/local/build.yml'
      YAML.load_file(build_configuration_file)
    end

    def status_urls
      url_set = Hash.new()
      url_set['ping'] = url('/status/ping.EXT')
      url_set['check'] = url('/status/check.EXT')
      url_set['dependencies'] = url('/status/dependencies.EXT')
      url_set['settings'] = url('/status/settings')

      u = Hash.new()
      u['urls'] = url_set
      u
    end
  end

  ## Add some class level helper methods.
  helpers do

    # html escape text but don't turn a nil into an empty string.
    def self.safe_html_escape(arg)
      arg &&= html_escape(arg)
    end

    # Assemble context codes to specify the set of courses.  Explicit method is required since RestClient
    # doesn't correctly deal with multiple parameters with same name as yet.
    # could generalize this to pass in prefix.
    def self.course_list_string(courses)
      courses.inject("") { |result, course| result << "&context_codes[]=course_#{course}" }
    end

    # This method checks to see if the request is being made only for data for the stated userid.
    # It returns true if the request is NOT permitted.  It is phrased as a veto
    # because this method is only responsible for checking SOME conditions that might forbid the request.

    # Calls to this method also supply a code block used to check if the user is an admin.
    def self.vetoRequest(user, request_url)

      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: user: [#{user}] request_url: [#{request_url}]"

      # Make sure that someone explicit is making the request.
      return true if user.nil?

      # Find any user explicitly mentioned in the url.
      url_user = self.getURLUniqname(request_url)

      # Things are ok of there is no explict user or the user requested in the current user.
      return nil if url_user.nil?
      return nil if url_user.eql? user

      # Invoke block to check if the user is an admin.
      is_admin = yield user
      veto = is_admin ? nil : true
      logger.warn "#{self.class.to_s}:#{__method__}:#{__LINE__}: vetoed request by [#{user}] for information url: [#{request_url}]" unless veto.nil?

      veto
    end

    # extract a a uniqname in this url
    # It must come after a known data source. Any elements
    # after that element are ignored.
    # /StudentDashboard/courses/ststvii.json
    # /StudentDashboard/?UNIQNAME=ststvii
    # /StudentDashboard/terms/ststvii.json
    # /todolms/ralt.json
    # /todolms/ralt/ctools.json

    # maybe put the sources (courses, terms, todolms, in a list?)
    def self.getURLUniqname(url)

      regex_courses = /courses\/([^.\/]+)/
      regex_terms = /terms\/([^.\/]+)/
      regex_todolms = /todolms\/([^.\/]+)/
      regex_UNIQUNAME = /\?UNIQNAME=(.+)/

      r = regex_courses.match(url)
      return r[1] unless r.nil?

      r = regex_terms.match(url)
      return r[1] unless r.nil?

      r = regex_todolms.match(url)
      return r[1] unless r.nil?

      r = regex_UNIQUNAME.match(url)
      return r[1] unless r.nil?

      # if didn't match anything then nothing to return.
      nil
    end

    ### Standard error message for bad request format, escape output to prevent cross site scripting.
    def bad_format_error(response, msg, format)
      response.status = 400
      erb "format missing or not supported: #{CourseList.safe_html_escape(format)}"
    end

  end

  helpers do
    # Run an self-directed url request for data and get the json out of the result.
    # The response is returned in a WAPI wrapper so error checking has been done.
    # by the data url processing.
    def run_url_parse_json(new_url)
      status, headers, request_body = call! env.merge("PATH_INFO" => new_url)
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: #{new_url}: request_body[0].inspect: +++#{CourseList.limit_msg(request_body[0].inspect)}+++"
      request_body_ruby = JSON.parse request_body[0]
      request_body_ruby
    end

    # Get the canvas courses from the list provided by mpathways.
    def getCanvasCourseList(course_data, userid)
      # could the regexp be a constant?
      instructure_regexp = Regexp.new(/instructure.com\/courses\/(\d+)/)

      # get the course link urls, extract course number (if canvas per regexp), remove nil from non-matches.
      # Push(nil) is added to make sure there is at least 1 nil.

      mpathways_canvas_courses = CourseList.getValuesForKey('Link', course_data.value).map { |link| instructure_regexp.match(link); $1 }
                                     .push(nil).compact.sort.uniq
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: uniq mpathways_canvas_courses: #{mpathways_canvas_courses}"

      mpathways_canvas_courses
    end
  end

  helpers do
    # generate the check url information for formatting elsewhere.
    def check_esb(format)

      st = Stopwatch.new("timing of check url")
      st.start
      check_result = dataProviderCheck()
      st.stop

      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: status: #{check_result.inspect}"

      if (check_result.meta_status == 200)
        response.status = 200
        maybe_ok = "OK"
      else
        response.status = check_result.meta_status
        maybe_ok = "NOT OK"
      end

      config_hash = settings.latte_config

      status = Hash.new
      status['status'] = maybe_ok
      status['elapsed'] = sprintf '%.3f', st.summary[0]
      status['server'] = config_hash[:server]
      status
    end

  end

  ############ Process request URLs ##############

  # Requests are matched and processed in the order matchers that appear in the code.  Multiple matches may happen
  # for a single request if the processing for one match uses 'pass' to let matching code later in the chain process.

  # Before clauses are filters that apply before the verb based processing happens.
  # These before clauses deal with authentication.

  # If permitted take the remote user from the session.  This
  # allows overrides to work for calls from the UI to the REST API.

  # if the URL has /self/ instead of a uniqname then replace self with the current user and redirect.
  before /\/self(\Z|(\/|\/[\w\/]+)?(\.\w+)?)$/ do
    original = String.new(request.env['PATH_INFO'])
    self_user = session[:remote_user]
    request.env['PATH_INFO'] = request.env['PATH_INFO'].gsub('/self', "/#{self_user}")
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: modified request [#{original}] to be: [#{request.env['PATH_INFO']}] and redirecting"
    redirect to(request.env['PATH_INFO'])
  end

  # If explicit suffix then make sure the accept header contains it.

  before /.*/ do
    request.accept.unshift('application/json') if request.url.match(/.json$/)
    request.accept.unshift('text/html') if request.url.match(/.xml$/)
    request.accept.unshift('text/plain') if request.url.match(/.txt$/)
  end


  # NOTE data rest calls to self
  # The final Result for a data call is a JSON string from the WAPI wrapper.  If you need to pass it on
  # convert to Ruby and then add to the new WAPI wrapper.  Just passing on the JSON string
  # means the JSON string itself will end up escaped again.

  before "*" do

    # Need to set session user and remote user. The Remote user is the authenticated user. Session user
    # the effective user.  They may differ if the user is considered an admin.

    config_hash = settings.latte_config

    # Get a user name. If there is no remote_user then set it to default.  This can happen in development.
    user = request.env['REMOTE_USER']
    if user.nil? || user.length == 0
      user = config_hash[:default_user]
    end

    ## Now check to see if allowed to override the user.
    if allow_uniqname_override user
      ## If allowed and there is an user in the session then use that.
      session_user = session[:remote_user]
      if !session_user.nil? && session_user.length > 0
        user = session_user
        logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}:  authn filter: using session user: #{user}"
      end
    end

    ## Set that remote user to the computed user.
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: remote_user: [#{request.env['REMOTE_USER']}] computed user: [#{user}]"
    request.env['REMOTE_USER'] = user

    # Start a request timer.
    msg = Thread.current.to_s + "\t"+request.url.to_s
    sd = Stopwatch.new(msg)
    sd.start

    # Store a stack of stopwatches since Dash calls back to itself.
    session[:thread] = Array.new if session[:thread].nil?
    session[:thread].push(sd)

  end

  ## For testing allow specifying the userid identity to be used on the URL.
  ## This is particularly useful for load testing.  The switch in userid name
  ## only applies to requests for the top level Dashboard page.  This processing
  ## is off by default.
  before '/' do
    ## Check and possibly override the user id
    uniqnameOverride if allow_uniqname_override request.env['REMOTE_USER']
  end

  ## Check that the request for userid data is allowed.
  before "*" do

    vetoResult = CourseList.vetoRequest(request.env['REMOTE_USER'], request.env['REQUEST_URI']) { admin_user request.env['REMOTE_USER'] }
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: REQUEST: * end veto check: user: [#{request.env['REMOTE_USER']}] [#{vetoResult}]"
    halt 403 if vetoResult == true
  end

  ######################################
  ########### STATUS URLS ##############
  ######################################
  # top level request for status information and urls

  get '/status.?:format?/?' do |format|
    format = CourseList.safe_html_escape(format)
    format = 'html' unless (format)
    format.downcase!

    # Assemble the raw top level of status information by merging hashs from
    # different sources.  The @information instance variable is set to be available to the templates.
    @information = build_info().merge(status_urls())

    # set default template and content type
    content_type :html
    template = :'status.html'
    # override default if appropriate
    if ('json'.eql? format) then
      content_type :json
      template = :'status.json'
    end

    # render response
    erb template
  end

  # Trivial request to verify that the server can respond.
  get '/status/ping.?:format?' do |format|
    format = CourseList.safe_html_escape(format)
    format = 'html' unless (format)

    if format && "json".casecmp(format) == 0 then
      content_type :json
      Hash['status', 'ok'].to_json
    else
      "ok"
    end

  end

  # Verify that a simple round trip, using the ESB dependency, works.
  get '/status/check.?:format?' do |format|
    format = CourseList.safe_html_escape(format)
    format = 'html' unless (format)
    status_hash = check_esb(format)
    if format && "json".casecmp(format) == 0 then
      content_type :json
      return_value = status_hash.to_json
    else
      return_value = sprintf "status=%s elapsed=%s server=%s",
                             status_hash['status'], status_hash['elapsed'], status_hash['server']
    end
    return_value
  end

  # for backward compatibility forward to the new check implementation.
  get '/check' do
    status, headers, body = call env.merge("PATH_INFO" => '/status/check')
  end

  get '/status/dependencies.?:format?' do |format|
    format = CourseList.safe_html_escape(format)
    format = 'html' unless (format)
    config_hash = settings.latte_config
    app_hash = Hash.new
    config_hash.keys.grep(/_name$/) { |name| app_hash[name] = config_hash[name] }
    @information = app_hash
    if format && "json".casecmp(format) == 0 then
      content_type :json
      template = :'dependencies.json'
    else
      template = :'dependencies.html'
    end
    erb template
  end

  ## Dump configuration settings to log upon request
  get '/status/settings' do
    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: PRINT CURRENT CONFIGURATION SETTINGS"
    config_hash = settings.latte_config

    config_hash.keys.sort_by { |k| k.to_s }.map do |key|
      logger.info "KEY: #{key}\tVALUE: [#{config_hash[key]}]"
    end
    "settings dumped to log file"
  end

  ######################################
  ########### URL ROUTERS ##############
  ######################################

  ## Process the user / data requests based on the URL

  ## If the request isn't for anything specific then return the UI page.
  get '/' do

    config_hash = settings.latte_config

    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{config_hash[:BASE_DIR]}/UI/index.erb")

    # Make some values available to the UI.
    @server = config_hash[:server]
    @remote_user = request.env['REMOTE_USER']
    @build_time = config_hash[:build_time]
    @build_id = config_hash[:build_id]

    # Make the hash of standard text strings available.
    @strings = config_hash[:strings]["strings"]

    # This MUST be the last statement since it returns the output text.
    erb idx
  end

  ### Print the API documentation.
  get '/api' do
    @@apidoc
  end

  ### Return json array of the course objects for this user to the UI.  Currently if you don't
  ### specify the json suffix it is an error.
  get '/courses/:userid.?:format?' do |userid, format|
    userid = CourseList.safe_html_escape(userid)
    format = CourseList.safe_html_escape(format)
    termid = CourseList.safe_html_escape(params[:TERMID])

    if format && "json".casecmp(format).zero?
      content_type :json
      course_data = dataProviderCourse(userid, termid)
      if "404".casecmp(course_data.meta_status.to_s).zero?
        logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}:returning 404 for missing information: userid: #{userid} termid: #{termid}"
        response.status = 404
        return ""
      end
    else
      return bad_format_error(response, "/courses request: bad format", format)
    end

    # As a by-product save the list of canvas course ids.
    session[:canvas_courses] = getCanvasCourseList(course_data, userid)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: session: active canvas_courses list: #{session[:canvas_courses]}"

    course_data.value_as_json
  end

  ################# get the terms

  ## ask for terms from the current user.
  get "/terms/?" do
    content_type :json

    termList = dataProviderTerms(request.env['REMOTE_USER'])
    termList.value_as_json
  end

  ## ask for terms for a specific person.
  get "/terms/:userid.?:format?" do |userid, format|
    userid = CourseList.safe_html_escape(userid)
    format = CourseList.safe_html_escape(format)

    userid = request.env['REMOTE_USER'] if userid.nil?

    ## The check for json implies that other format types will fail.
    format = "json" unless (format)

    if format && "json".casecmp(format).zero?
      content_type :json
    else
      return bad_format_error(response, "/terms request: bad format", format)
    end

    termList = dataProviderTerms(userid)
    termList.value_as_json
  end

  ### todolms:  get information about assignments from various data sources.

  # For REST compatibility list the urls that contribute todolms data.
  get "/todolms/:userid.?:format?" do |userid, format|
    format = CourseList.safe_html_escape(format)
    format = 'json' unless (format)
    format.downcase!

    return bad_format_error(response, "/todolms request only supports json", format) unless format && "json".casecmp(format).zero?

    @information = ['canvas','ctools','ctoolspast','mneme'].map {|lms| url("/todolms/#{userid}/#{lms}.json")}
    content_type :json
    template = :'todolms.json'

    erb template
  end

  # route to the appropriate data source for this request.
  get "/todolms/:userid/:lms.?:format?" do |userid, lms, format|
    userid = CourseList.safe_html_escape(userid)
    lms = CourseList.safe_html_escape(lms)
    format = CourseList.safe_html_escape(format)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: generic /todolms/#{userid}/#{lms}"

    userid = request.env['REMOTE_USER'] if userid.nil?

    ## The check for json implies that other format types will fail.
    format = "json" unless (format)

    if format && "json".casecmp(format).zero?
      content_type :json
    else
      return bad_format_error(response, "/todolms request: bad format", format)
    end

    config_hash = settings.latte_config
    todolmsList = dataProviderToDoLMS(userid, lms)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: /todolms/#{userid}/#{lms}: "+CourseList.limit_msg(todolmsList.inspect)

    todolmsList
  end

  #################################################
  ############### Supply static external resources
  #################################################
  # External resource request expects to get request for a resource at or under /external.
  # Processing is passed to an external resource provider.
  # If request is to directory (if the file_name is nil) then return a json list of the objects in directory.
  # If request is for a specific file then return that file.
  # If there isn't a list of items in the directory or there isn't a file then return nil / 404.
  # Definition of contents of /external and sub-directories and files is application
  # dependent.  For Student Dashboard the sub-directories are image and text.  The list of
  # the valid sub-directories is configurable.

  # This recognizes only 1 level of directory and optional file under /external
  get '/external/?:directory?/?:file_name?' do |directory, file_name|

    directory = CourseList.safe_html_escape(directory)
    file_name = CourseList.safe_html_escape(file_name)

    er = dynamic_hash[:external_resources]

    config_hash = settings.latte_config
    valid_directories = config_hash[:external_resources_valid_directories]

    # forbid looking at any non-valid directories.
    halt 403 unless directory.nil? || valid_directories.include?(directory)

    result = er.get_resource(directory, file_name)

    # if not found say so.
    halt 404 if result.nil?

    # get the return content type based on the file extension.
    file_name =~ /\.([^.]+)$/
    file_extension = $1
    content_type file_extension

    result
  end
  ################# end of external resources

  #################################################
  ## catch any un-matched requests.
  #################################################
  get '*' do
    config_hash = settings.latte_config
    response.status = 400
    return "#{config_hash[:invalid_query_text]}"
  end

  #######################################################
  # Post process requests to generate timing information.
  #######################################################
  after do
    request_sd = session[:thread].pop
    ## if redirect from self then the stopwatch doesn't get setup.
    unless request_sd.nil?
      request_sd.stop
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: stopwatch: "+request_sd.pretty_summary
    end
  end

end
