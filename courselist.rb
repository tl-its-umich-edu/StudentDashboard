require 'sinatra/base'
require 'json'
require 'slim'
require 'yaml'
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
#                         logger.info "ls config: #{@@ls}"
                       end

#  helpers DataHelper Sinatra::JSON

#  localSettings = YAML.load_file('test.yml')
#  puts localSettings
  helpers DataHelper

  # Indent html for pretty debugging and do not sort attributes (Ruby 1.9)

  # pretty print html for development
  Slim::Engine.set_default_options pretty: true, sort_attrs: false

  get '/' do
    slim :home
  end

  get '/settings' do
#    ls = YAML.load_file('local/local.yml').to_json
    logger.info "@@ls: (json) #{@@ls}"
    "settings dumped to log file"
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

  get '/courses/:userid.?:format?' do |user, format|
    logger.info "courses/:userid: #{user} format: #{format}"
    if "json".casecmp(format).zero? 
      content_type :json
      ## call helper with parameters and get back locals array to pass to slim template engine.
      courseDataForX = CourseData(user)
      logger.info "courseData #{courseDataForX}"
      courseDataForX.to_json
    else
      response.status = 400
      return "format not supported: #{format}"
    end
  end

  ## catch everything not matched and give an error.
  get '*' do
    response.status = 400
    return "invalid query"
  end


  # get '/examples/block_parameters/:id' do |id|
  #                                         ...
  # end

  # ##  use normal parameters
  # get '/examples/params/:id' do
  #   params[:id]
  # end

# require 'yaml' # STEP ONE, REQUIRE YAML!
# # Parse a YAML string
# YAML.load("--- foo") #=> "foo"

# # Emit some YAML
# YAML.dump("foo")     # => "--- foo\n...\n"
# { :a => 'b'}.to_yaml  # => "---\n:a: b\n"

# require 'yaml'
# thing = YAML.load_file('some.yml')
# puts thing.inspect
end

