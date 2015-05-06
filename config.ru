$: << File.dirname(__FILE__)
require './server/courselist'

set :environment, :development

#require 'newrelic_rpm'
run CourseList.new
# studentdashboard directory


