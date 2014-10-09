### Simple rest server for SD data
### This version will also server up the HTML page if no
### specific page is requested.

### Sinatra is a DSL (domain specific language) for working with HTTP requests.

require 'sinatra'
require 'json'
require 'slim'
require 'yaml'
require './server/WAPI'

class CourseList < Sinatra::Base

  ### Class variables

  ### response to query that is not understood.
  @@invalid = "invalid query. what U want?"

  ## base directory to ease referencing files in the war
  @@BASE_DIR = File.dirname(File.dirname(__FILE__))

  @@yaml = "HOWDY"

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

#### Ruby approach to configuring environment.

  set :environment, :development
### configuration
## make sure logging is available
  configure :production, :development do
    enable :logging
    log = File.new("server/log/sinatra.log", "a+")
    $stdout.reopen(log)
    $stderr.reopen(log)

    $stderr.sync = true
    $stdout.sync = true

    ## look for the UI files in a parallel directory.
    ## this may not be necessary.
    f = File.dirname(__FILE__)+"/../UI"
    puts "UI files: "+f
    set :public_folder, f

    # read in yaml configuration into a class variable
    @@ls = YAML.load_file('server/local/local.yml')

  end

  ########### URL ROUTERS ##############
  # Note that the first matching clause will win.

  ## If the request isn't for anything specific then return the UI page.

  ### Return the index.html page but replace the value of UNIQNAME by
  ### the contents of the request remote user parameter.  This approach is a hack.

  get '/' do
    ### Currently pull the erb file from the UI directory.
    idx = File.read("#{@@BASE_DIR}/UI/index.erb")

    # get some value for remote_user even if it isn't in the request.
    @remote_user = request.env['REMOTE_USER']
    @remote_user = "anonymous" if @remote_user.nil? || @remote_user.empty?

#    @remote_user = request.env['REMOTE_USER'] || "anonymous"
#    @remote_user = request.env['REMOTE_USER'] || "jorhill"
    puts "@remote_user: #{@remote_user}"

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
      logger.info "courseDataForX: #{courseDataForX}"
      if "404".casecmp(courseDataForX).zero?
        logger.debug("returning 404 for missing file")
        response.status = 404
        return ""
      end

      # parse return value as json so it is converted from string
      # format.
      courseDataForXJson = JSON.parse courseDataForX
      logger.info "courseData #{courseDataForX}"

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
    return "#{@@invalid}"
  end


  #################### Data provider functions #################


  ### Grab the desiried data provider.
  ### Need to make the provider selection settable via properties.
  def CourseDataProvider(a)
    #return CourseDataProviderStatic(a)
    puts "CourseDataProvider a: #{a}"
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
    puts "data provider is CourseDataProviderFile.\n"

    dataFile = "#{@@BASE_DIR}/"+@@ls['data_file_dir']+"/"+@@ls['data_file_type']+"/#{a}.json"
    puts "data file string: "+dataFile

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
    puts "data provider is CourseDataProviderESB.\n"
    ## if necessary initialize the ESB connection.
    if @w.nil?
      @w = initESB
    end

    url = "/Students/#{uniqname}/Terms/2010/Schedule"

    logger.debug("ESB: url: "+url)
    puts "ESB: url: "+url
    puts "@w: "+@w.to_s

    classes = @w.get_request(url)
    logger.debug("returning: "+classes)
    return classes
  end


  def initESB
    @@yaml_file = "./server/spec/security.yaml"
    @@yaml= YAML.load_file(@@yaml_file)
    app_name="SD-QA"
    setup_WAPI(app_name)
  end

  def setup_WAPI(app_name)
    application = @@yaml[app_name]
    @w = WAPI.new application
  end

  ##### Trivial static data provider
  def CourseDataProviderStatic(a)
    puts "data provider is CourseDataProviderStatic\n"
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

