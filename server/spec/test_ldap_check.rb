# Unit test checks that can veto in appropriate users
# from get information on other people.

require_relative 'test_helper'
require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'rest-client'
require 'logger'
require 'yaml'
require_relative '../../server/Logging'

## set the environment for testing
#ENV['RACK_ENV'] = 'test'



require 'net-ldap'

require_relative '../ldap_check'

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

class LdapTest < MiniTest::Test
  include Logging


  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # by default assume the tests will run well and don't need
    # to have detailed log messages.
    logger.level = Logger::ERROR

    @x = LdapCheck.new({ "port" => 'sldkfj'})
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # def test_memberFilter
  #   m = LdapCheck.new({"filter_prefix" => "FIRST", "filter_suffix" => "LAST"})
  #   f = @x.memberFilter("them")
  #   assert_equal("(&(cn=them) (objectclass=rcf822MailGroup))",f,"build correct member filter")
  # end

  #def test_yml
#
#  end

  # # GET THE DISPLAY NAME AND E-MAIL ADDRESS FOR A SINGLE USER
  # search_param = "lstarr"
  # result_attrs = ["sAMAccountName", "displayName", "mail"]
  #
  # # Build filter
  # search_filter = Net::LDAP::Filter.eq("sAMAccountName", search_param)
  #
  # # Execute search
  # ldap.search(:filter => search_filter, :attributes => result_attrs, :return_result => false) { |item|
  #   puts "#{item.sAMAccountName.first}: #{item.displayName.first} (#{item.mail.first})"
  # }
  #

  #F='(&(cn=ctsupportstaff)(objectclass=rfc822MailGroup))'
  #ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu" -L $F member
  # filter: '(&(member=uid=dlhaines,ou=People,dc=umich,dc=edu)(cn=its tl staff))'

  def find_user_in_ldap_members user, members
    puts "user: #{user} members: #{members}"
    found = false
    members.each { |e| found = true if e.start_with? "uid=#{user}," }
    found
  end

  def find_user_in_ldap_members_any user, members
    members.any? { |e| e.start_with? "uid=#{user}," }
  end

  def test_raw()
    puts "test_raw"
    Net::LDAP.open(:host => "ldap.itd.umich.edu",
                   :port => 389,
                   :base => "ou=Groups,dc=umich,dc=edu") do |ldap|
      # Do all your LDAP stuff here...
      p ldap

      #fstring = '(&(cn=ctsupportstaff)(objectclass=rfc822MailGroup))'
      #group = "its tl staff"
      group = "ctsupportstaff"
      user = "dlhaines.XXX"
      #fstring = '(&(member=uid=dlhaines,ou=People,dc=umich,dc=edu)(cn=its tl staff))' # works to get all
      #fstring = "(&(member=uid=dlhaines,ou=People,dc=umich,dc=edu)(cn=#{group}))" # works to get all
      #fstring = "(&(member=uid=#{user},ou=People,dc=umich,dc=edu)(cn=#{group}))" # works to get all

      #fstring = "(cn=#{group})" # works to get all

      fstring = "(&(cn=#{group})(objectclass=rfc822MailGroup))"

      f = Net::LDAP::Filter.construct(fstring)
      puts "filter: f: "
      p f
      x = ldap.search(:filter=>f)
      puts "search result x:"
      p x.each {|a| puts a}

      puts "dn:"
      p x[0].dn
      found = false
      puts "members"
      x[0].member.each   { |e| puts e}
      x[0].member.each   { |e| found = true if e.start_with? "uid=#{user}," }
      #ldap.search(...)

      puts "found: #{found}"

      find_by_method = find_user_in_ldap_members_any "dlhaines.XXX", x[0].member
      puts "fuilm: ", find_by_method
    end
  end

  #### NOTE: this method can veto requests, so the "assert r" is checking that
  # #### that the request is vetoed and "refute r" checks that the request is
  # #### not vetoed.
  # #### NOTE: The messages describe the failure state of the test.
  #
  # ### test that have a user to check against.
  # def test_nil_user_fails
  #   r = CourseList.vetoRequest nil, @coursesUrlststvii
  #   assert r, "veto if no authenticated user (nil)"
  # end
  #
  # def test_empty_user_fails
  #   r = CourseList.vetoRequest "", @coursesUrlststvii
  #   assert r, "veto if no authenticated user (empty string)"
  # end
  #
  #
  # ### check to make sure unauthorized user can not request courses but
  # ### and anothorized user can
  # def test_mismatched_user
  #   r = CourseList.vetoRequest "abba", @coursesUrlststvii
  #   assert r, "allowed wrong user."
  # end
  #
  # ## make sure that the user matches
  # def test_matched_user
  #   r = CourseList.vetoRequest "ststvii", @coursesUrlststvii
  #   refute r, "refused correct user"
  # end
  #
  # ### Check that administrative users can do anything
  #
  # #def test_admin_user_works
  # #  skip("user from admin list should not be vetoed")
  # #end
  #
  # ####### check that don't affect irrelevant URLS
  #
  # def test_topUrl
  #   r = CourseList.vetoRequest "ststvii", @topUrl
  #   refute r, "refused correct url"
  # end
  #
  # def test_topSDUrl
  #   r = CourseList.vetoRequest "ststvii", @topSDUrl
  #   refute r, "refused correct url"
  # end
  #
  # def test_topSDUrlUNIQNAME_different
  #   r = CourseList.vetoRequest "ststvii", @topSDUrlUNIQNAME_different
  #   refute r, "refused correct url (url does not have /courses/)"
  # end
  #
  # def test_topSDUrlUNIQNAME_same
  #   r = CourseList.vetoRequest "ststvii", @topSDUrlUNIQNAME_same
  #   refute r, "refused correct url"
  # end

end
