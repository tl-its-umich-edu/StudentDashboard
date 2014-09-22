$: << File.dirname(__FILE__)
require './server/courselist'

set :environment, :development

run CourseList.new
# studentdashboard directory


