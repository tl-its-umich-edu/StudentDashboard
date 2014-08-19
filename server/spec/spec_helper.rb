$: << File.expand_path('../..', __FILE__)

require 'courselist'
require 'rack/test'

def app
  CourseList.new
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
