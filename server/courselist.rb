### Simple rest server for SD data
require 'sinatra'
require 'json'
require 'slim'
require 'yaml'

class CourseList < Sinatra::Base

  ## class variable for strings
  @@invalid = "invalid query. what U want?"

  ## make sure logging is available
  configure :production, :development do
                         enable :logging
                         log = File.new("log/sinatra.log", "a+") 
                         $stdout.reopen(log)
                         $stderr.reopen(log)

                         $stderr.sync = true
                         $stdout.sync = true

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
        }
      ]
    
    return classJson
  end
  

  ## dump settings upon request
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
      return "format missing or not supported: #{format}"
    end
  end

  ## catch everything not matched and give an error.
  get '*' do
    response.status = 400
    return "#{@@invalid}"
  end

end

