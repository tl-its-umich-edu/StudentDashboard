### Simple rest server for SD data
require 'sinatra'
require 'json'
require 'slim'
require 'yaml'

class CourseList < Sinatra::Base

  ### Class variables for documentation

  @@invalid = "invalid query. what U want?"

  ## api docs
  @@apidoc = <<END

<p/>
HOST://api - this documentation.
 <p/>
HOST://courses/{uniqname}.json - An array of (fake) course data for this person.
 <p/> 
HOST://settings - dump data to the log.

<p/>
It could use a bit of improvement so feel free to help!

END

                  ### configuration
                  ## make sure logging is available
                  configure :production, :development do
                                         enable :logging
                                         log = File.new("log/sinatra.log", "a+")
                                         $stdout.reopen(log)
                                         $stderr.reopen(log)

                                         $stderr.sync = true
                                         $stdout.sync = true
                                         
                                         ## look for the UI files in a parallel directory.
                                         f = File.dirname(__FILE__)+"/../UI"
                                         puts "UI files: "+f
                                         set :public_folder, f

                                         # read in yaml configuration into a class variable
                                         @@ls = YAML.load_file('local/local.yml')
                                         ## logger doesn't work from here ??
                                       end

  ### helper function
  def CourseData(a)
    classJson = 
      [
        { :title => "English 323",
          :subtitle => "Austen and her contemporaries and #{a}",
          :location => "canvas",
          :link => "google.com",
          :instructor => "me: #{a}",
          :instructor_email => "howdy ho"
        },
        { :title => "German 323",
          :subtitle => "Beeoven and her contemporaries and #{a}",
          :location => "ctools",
          :link => "google.com",
          :instructor => "you: Mozarty",
          :instructor_email => "howdy haw"
        },
        { :title => "Philosophy 323",
          :subtitle => "Everybody and nobody at all along with you: #{a}",
          :location => "none",
          :link => "google.com",
          :instructor => "Life",
          :instructor_email => "google@google.goo"
        }
      ]
    
    return classJson
  end

 @@FAKE_UNIQNAME = ["ME","YOU","THEY","instx","dlhaines","csev"]

  ########### ROUTERS ##############

  ### TESTING:
#### for the moment generate a fake uniqname in request.env['REMOTE_USER'] 
#### for each request so can checkout what happens when different uniqnames are used.
#### This entire "before" section can be deleted when this testing is done as it
#### works by resetting the variable the real code will use.
  before do
   offset = Random.rand(@@FAKE_UNIQNAME.length)
    fake_uname = @@FAKE_UNIQNAME[offset]
    puts "fake_uname: #{fake_uname} offset: #{offset}"
    request.env['REMOTE_USER'] = fake_uname
  end

  ## by default invoke the UI.

  ### return the index.html page but replace the value of UNIQNAME by
  ### the contents of the request remote user parameter.
  get '/' do
    puts "remote user: "+request.env['REMOTE_USER']
    remoteUser = request.env['REMOTE_USER']
    idx = File.read("../UI/index.html")
    idx = idx.gsub(/UNIQNAME/,remoteUser);
    erb idx
  end 

  ### get documentation
  get '/api' do
    @@apidoc
    ## inline may require classic, not modular, organization
 #    slim :apidocA
  end

  ## dump settings to log upon request`
  get '/settings' do
    logger.info "@@ls: (json) #{@@ls}"
    "settings dumped to log file"
  end

  ### return json array of the course objects for this user.  Not specifying 
  ### json as format is an error
  get '/courses/:userid.?:format?' do |user, format|
    logger.info "courses/:userid: #{user} format: #{format}"
    if format && "json".casecmp(format).zero? 
      content_type :json
      courseDataForX = CourseData(user)
      logger.info "courseData #{courseDataForX}"
      courseDataForX.to_json
    else
      response.status = 400
      return "format missing or not supported: [#{format}]"
    end
  end

  ## catch everything not matched and give an error.
  get '*' do
    response.status = 400
    return "#{@@invalid}"
  end

end

__END__

###### Line templates are here.

### API documentation as slim template.
@@ apidocA
 h1 This is the API documentation
  h2 '/api' will return api documentation.
  h2 '/courses/{userid}.json' will return course objects for this user.

