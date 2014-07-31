require 'sinatra/base'
require 'slim'

### Use parameters in addressbook

class CourseList < Sinatra::Base
  get '/' do
    slim :home
  end

  get '/courses/:userid' do |user|
    slim :courses, locals: {userid: user}
  end

  # ## use block parameters
  # get '/examples/block_parameters/:id' do |id|
  #                                         ...
  # end

  # ##  use normal parameters
  # get '/examples/params/:id' do
  #   params[:id]
  # end

end

## want to return information in this format
# {
#       "title": "English 323",
#       "subtitle": "Austen and her contemporaries",
#       "location": "canvas",
#       "link": "https://some.canvas.url",
#       "instructor": "Jane Austen",
#       "instructor_email": "jausten@umich.edu"
#   }
