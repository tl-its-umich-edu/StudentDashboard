require 'sinatra/base'
require 'slim'
require 'helpers/DataHelper'

class CourseList < Sinatra::Base

  helpers DataHelper

  get '/' do
    slim :home
  end

  # using block parameters
  get '/courses/:userid' do |user|
    ## call helper with parameters and get back locals array to pass to slim template engine.
    courseListForX = HelloWorld(user)
    slim :courses, locals: {userid: courseListForX}
  end


  # get '/examples/block_parameters/:id' do |id|
  #                                         ...
  # end

  # ##  use normal parameters
  # get '/examples/params/:id' do
  #   params[:id]
  # end

end

