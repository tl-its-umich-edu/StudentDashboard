require File.expand_path(File.dirname(__FILE__) + '/data_provider_esb.rb')
include DataProviderESB

class PollESB
  require 'json'
  require 'yaml'
  require_relative 'WAPI'
  require_relative 'WAPI_result_wrapper'

  include Logging

  ### class instance variables for holding class state.
  # do it this many times
  @times_max = 5000
  # how many times it's been done.
  @iterations = 0
  # security file
  @security_file = './spec/security.yml'
  # configuration
  #@c = nil
  # WAPI object
  @w = nil
  # security configuration
  @yml = nil
  # application name
  @application_name = "SD-QA"
  # seconds to sleep
  @sleep = 60

  @tries_per_line = 30

  @error_file = 'poll_esb_errors.txt'
  
  def self.setupLogging
    logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG
  end

  def self.do_something(num, msg)
    puts "#{num}:."
  end

  self.setupLogging

  @times_max.times do |i|
    if @iterations % @tries_per_line == 0
      print "\n"+Time.now.to_s+": "
    end
    @iterations = i+1
    begin
      classes = DataProviderESBCourse("ststvii", "2010", @security_file, @application_name, 2010)
    rescue => exp
      open(@error_file, 'a') { |f| f.puts Time.now.to_s+ "\tDataProviderESBCourse exception: "+exp.inspect}
    end
    begin
      http_status = classes.meta_status
    rescue => exp
      http_status = 666
    end

    out = (http_status == 200)? "." : "-"

    print "#{out}"
    sleep @sleep
  end

end
