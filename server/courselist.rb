### Simple rest server for SD data
require 'sinatra/base'
require 'json'
require 'slim'
require 'yaml'
## Get the actual course information for a user.
require 'helpers/DataHelper'

class CourseList < Sinatra::Base

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

  helpers DataHelper

  # pretty print html for development
  Slim::Engine.set_default_options pretty: true, sort_attrs: false

  ## dump settings upon request
  get '/settings' do
    logger.info "@@ls: (json) #{@@ls}"
    "settings dumped to log file"
  end

  ### return json array of course object for this user.  Not specifying 
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
    return "invalid query"
  end

end

