$: << File.dirname(__FILE__)
require './courselist'
#require 'newrelic_rpm'

set :environment, :development

run CourseList.new
# server directory

