require 'sinatra/base'
#require 'sinatra/json'
require 'json'
require 'slim'
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
                       end

#  helpers DataHelper Sinatra::JSON
  helpers DataHelper

  # Indent html for pretty debugging and do not sort attributes (Ruby 1.9)

  # pretty print html for development
  Slim::Engine.set_default_options pretty: true, sort_attrs: false

  get '/' do
    slim :home
  end

 get '/courses.json/:userid' do |user|
   content_type :json
   { :key1 => 'value1', :key2 => user } .to_json
 end

  # using block parameters
  get '/hello/:userid' do |user|
    ## call helper with parameters and get back locals array to pass to slim template engine.
    courseListForX = HelloWorld(user)
    slim :hello, locals: {userid: courseListForX}
  end

  get '/courses/:userid' do |user|
    ## call helper with parameters and get back locals array to pass to slim template engine.
    logger.info "courses/:userid: #{user}"
    courseDataForX = CourseData(user)
    slim :courses, locals: {userid: user, courseData: courseDataForX}
  end


  # get '/examples/block_parameters/:id' do |id|
  #                                         ...
  # end

  # ##  use normal parameters
  # get '/examples/params/:id' do
  #   params[:id]
  # end

end

