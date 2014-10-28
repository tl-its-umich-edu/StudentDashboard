
require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'rest-client'
require 'logger'
require 'yaml'

## set the environment for testing
ENV['RACK_ENV'] = 'test'

require '../courselist'

#email_regex: !ruby/regexp '/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i'



##<Sinatra::Request:0x007fd822df6bf8
# @env={"GATEWAY_INTERFACE"=>"CGI/1.1", "PATH_INFO"=>"/courses/ststviixxx.json", "QUERY_STRING"=>"",
# "REMOTE_ADDR"=>"127.0.0.1", "REMOTE_HOST"=>"localhost", "REQUEST_METHOD"=>"GET",
# "REQUEST_URI"=>"http://localhost:3000/courses/ststviixxx.json", "SCRIPT_NAME"=>"", "SERVER_NAME"=>"localhost",
# "SERVER_PORT"=>"3000", "SERVER_PROTOCOL"=>"HTTP/1.1", "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/1.9.3/2013-11-22)",
# "HTTP_HOST"=>"localhost:3000",
# "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:32.0) Gecko/20100101 Firefox/32.0",
# "HTTP_ACCEPT"=>"application/json, text/plain, */*", "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.5",
# "HTTP_ACCEPT_ENCODING"=>"gzip, deflate", "HTTP_DNT"=>"1",
# "HTTP_REFERER"=>"http://localhost:3000/?UNIQNAME=ststviixxx", "HTTP_CONNECTION"=>"keep-alive",
# "HTTP_CACHE_CONTROL"=>"max-age=0",
# "rack.version"=>[1, 2],
# "rack.input"=>#<Rack::Lint::InputWrapper:0x007fd822df7a58 @input=#<StringIO:0x007fd8248fb390>>,
# "rack.errors"=>#<Rack::Lint::ErrorWrapper:0x007fd822df79e0 @error=#<File:server/log/sinatra.log>>,
# "rack.multithread"=>true, "rack.multiprocess"=>false, "rack.run_once"=>false, "rack.url_scheme"=>"http",
# "HTTP_VERSION"=>"HTTP/1.1", "REQUEST_PATH"=>"/courses/ststviixxx.json", "sinatra.commonlogger"=>true,
# "rack.logger"=>#<Logger:0x007fd822df78a0 @progname=nil, @level=0,
# @default_formatter=#<Logger::Formatter:0x007fd822df7878 @datetime_format=nil>, @formatter=nil,
# @logdev=#<Logger::LogDevice:0x007fd822df76e8 @shift_size=nil, @shift_age=nil, @filename=nil,
# @dev=#<Rack::Lint::ErrorWrapper:0x007fd822df79e0 @error=#<File:server/log/sinatra.log>>,
# @mutex=#<Logger::LogDevice::LogDeviceMutex:0x007fd822df76c0 @mon_owner=nil, @mon_count=0,
# @mon_mutex=#<Mutex:0x007fd822df75f8>>>>, "rack.request.query_string"=>"", "rack.request.query_hash"=>{}}, @params={}>

class AuthCheck < MiniTest::Test


  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
    @x = CourseList.new
    @coursesUrlststvii = "http://localhost:3000/courses/ststvii.json"
    @topUrl = "http://localhost:3000/"
    @topSDUrl = "http://localhost:3000/StudentDashboard"
    @topSDUrlUNIQNAME_different = "http://localhost:3000/StudentDashboard?UNIQNAME=ignoreme"
    @topSDUrlUNIQNAME_different = "http://localhost:3000/StudentDashboard?UNIQNAME=ststvii"
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_nil_user_fails
    r = CourseList.vetoRequest nil, @coursesUrlststvii
    assert r, "veto if no authenticated user (nil)"
  end

  def test_empty_user_fails
    r = CourseList.vetoRequest "", @coursesUrlststvii
    assert r, "veto if no authenticated user (empty string)"
  end

  ## make sure that the user does not match
  def test_mismatched_user
    r = CourseList.vetoRequest "abba", @coursesUrlststvii
    assert r, "allowed wrong user."
  end

  ## make sure that the user matches
  def test_matched_user
    r = CourseList.vetoRequest "ststvii", @coursesUrlststvii
    refute r, "refused correct user"
  end

  ## make sure other URLs aren't matched
  def test_topUrl
    r = CourseList.vetoRequest "ststvii", @topUrl
    assert r, "allowed incorrect url"
  end

  def test_topSDUrl
    r = CourseList.vetoRequest "ststvii", @topSDUrl
    assert r, "allowed incorrect url"
  end

  def test_topSDUrlUNIQNAME_different
    r = CourseList.vetoRequest "ststvii", @topSDUrlUNIQNAME_different
    assert r, "allowed incorrect url"
  end
  def test_topSDUrlUNIQNAME_same
    r = CourseList.vetoRequest "ststvii", @topSDUrlUNIQNAME_same
    assert r, "allowed incorrect url"
  end




end