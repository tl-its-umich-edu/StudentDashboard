require 'sinatra/base'
require 'slim'
require 'helpers/DataHelper'

class CourseList < Sinatra::Base

  helpers DataHelper

  get '/' do
    slim :home
  end

  # using block parameters
  get '/hello/:userid' do |user|
    ## call helper with parameters and get back locals array to pass to slim template engine.
    courseListForX = HelloWorld(user)
    slim :hello, locals: {userid: courseListForX}
  end

  get '/courses/:userid' do |user|
    ## call helper with parameters and get back locals array to pass to slim template engine.
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

