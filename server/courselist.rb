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

  # Hold data required if need to wait to simulate authn
  # processing time.
  @@authn_prng = nil
  @@authn_total_wait_time = 0
  @@authn_total_stub_calls = 0


  ## api docs
  @@apidoc = <<END

<p/>
HOST://api - this documentation.
 <p/>
HOST://courses/{uniqname}.json - An array of (fake) course data for this person.
 <p/> 
HOST://settings - dump data to the log.

<p/>
It could use improvement so feel free to help!  Please update this section with any 
API changes.

END

  ## This will get the requested or default configuration file.  It returns
  ## the contents of the file.

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

#### Ruby approach to configuring environment.

  set :environment, :development

  # def self.default_from_yml(setting_name, default_value)
  #   if !@@ls[setting_name].nil?
  #     @@authn_uniqname_override = default_value
  #   end
  # end


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

  ### configuration

  # configure :test do
  #   puts "in debug configure"
  #   exit 1
  # end

  ## make sure logging is available
  configure :production, :development do

    ## load requested or default yml file

    #enable :logging

    set :logging, Logger::DEBUG

    ## In Tomcat commenting these three will make output show up in localhost log.
    log = File.new(@@log_file, "a+")
    $stdout.reopen(log)
    $stderr.reopen(log)

    $stderr.sync = true
    $stdout.sync = true

    ## look for the UI files in a parallel directory.
    ## this may not be necessary.
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

  end

  ### Add helper to deal with stubbing the authentication for testing purposes.
  helpers do
    def uniqnameOverride

      #pass unless @@authn_uniqname_override == true

      # don't reset user if one has already been supplied
      #pass unless request.env['REMOTE_USER'].nil? || request.env['REMOTE_USER'].length == 0

      # See if there is a candidate to use as authenticated user name.
      uniqname = params['UNIQNAME']
      logger.debug "found uniqname: #{uniqname}"
      # don't reset user if don't have a name to reset it to.
      pass if uniqname.nil? || uniqname.length == 0

      # now reset the name
      logger.debug "switching REMOTE_USER to #{uniqname}."
      request.env['REMOTE_USER']=uniqname

      ## If desired wait for a variable amount of time before returning
      ## to simulate authentication time waits
      if !@@authn_prng.nil?
        wait_sec = @@authn_prng.rand(@@authn_wait_min..@@authn_wait_max)
        @@authn_total_wait_time += wait_sec
        @@authn_total_stub_calls += 1
        #sleep wait_sec
        logger.debug "wait_sec: #{wait_sec} auth total_wait: #{@@authn_total_wait_time} total_calls: #{@@authn_total_stub_calls}"
      end
    end
  end

  #### Process requests

  ###### Filter ######
  ## Allow resetting the user considered authenticated from URL.  Only used
  ## in test settings.  It only applies to requests for the Dashboard page.
  before '/' do

    uniqnameOverride if @@authn_uniqname_override == true

  end

  ########### URL ROUTERS ##############
  # Note that the first clause matching the url will win.

  ## If the request isn't for anything specific then return the UI page.

  get '/' do
    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{@@BASE_DIR}/UI/index.erb")

    # get some value for remote_user even if it isn't in the request.
    @remote_user = request.env['REMOTE_USER']
    @remote_user = @@anonymous_user if @remote_user.nil? || @remote_user.empty?
    @remote_user = request.env['REMOTE_USER'] || @@anonymous_user

    logger.info "REMOTE_USER: #{@remote_user}"

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
  get '/courses/:userid.?:format?' do |user, format|
    logger.info "courses/:userid: #{user} format: #{format}"
    if format && "json".casecmp(format).zero?
      content_type :json
      courseDataForX = CourseDataProvider(user)
      logger.info "courseData from provider #{courseDataForX}"
      if "404".casecmp(courseDataForX).zero?
        logger.debug("returning 404 for missing file")
        response.status = 404
        return ""
      end

      # parse return value as json so it is converted from string
      # format.
      courseDataForXJson = JSON.parse courseDataForX
      logger.info "courseData as json #{courseDataForXJson}"

      # return data as json
      courseDataForXJson.to_json

    else
      response.status = 400
      return "format missing or not supported: [#{format}]"
    end
  end

  ## catch any request not matched and give an error.
  get '*' do
    response.status = 400
    return "#{@@invalid_query_text}"
  end


  #################### Data provider functions #################

  ### Grab the desired data provider.
  ### Need to make the provider selection settable via properties.
  def CourseDataProvider(a)
    #return CourseDataProviderStatic(a)
    logger.debug "CourseDataProvider a: #{a}"
    #return CourseDataProviderFile(a)
    return CourseDataProviderESB(a)
  end

  ###### File provider ################
  ### Return the data from a matching file.  The file must be in a sub-directory
  ### under the directory specified by the property data_file_dir.
  ### The sub-directory will be the name of the type of data requested (e.g. courses)
  ### The name of the file must match the rest of the URL.
  ### E.g. localhost:3000/courses/abba.json would map to a file named abba.json in the 
  ### courses sub-directory under, in this case, the test-files directory.

  def CourseDataProviderFile(a)
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

  def CourseDataProviderESB(uniqname)
    logger.info "data provider is CourseDataProviderESB.\n"
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = initESB
    end

    url = "/Students/#{uniqname}/Terms/2010/Schedule"

    logger.debug("ESB: url: "+url)
    logger.debug("@@w: "+@@w.to_s)

    classes = @@w.get_request(url)
    logger.debug("CL: ESB returns: "+classes)
    r = JSON.parse(classes)['getMyClsScheduleResponse']['RegisteredClasses']
    r2 = JSON.generate r
    logger.debug "Course data provider returns: "+r2
    return r2
  end

  def initESB
    logger.info "initESB"

    logger.info("security_file: "+@@security_file.to_s)
    requested_file = @@security_file

    default_security_file = './server/local/security.yml'

    #@@yml = get_local_config_yml(requested_file, default_security_file)


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
   h2 '/courses/{userid}.json' will return course objects for this user.

