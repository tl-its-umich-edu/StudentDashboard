# Unit test checks that can veto in appropriate users
# from get information on other people.
require_relative 'test_helper'

require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require 'rest-client'
require 'logger'
require 'yaml'
require_relative '../courselist'
## set the environment for testing
ENV['RACK_ENV'] = 'TEST'

class TestCourseList < MiniTest::Test

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # by default assume the tests will run well and don't need
    # detailed log messages

    logger.level = Logger::ERROR

    ## create a Latte application
    ## The ! should get rid of the middle ware.
    @x = CourseList.new!

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_instanciate
    assert @x, "did not create Latte object"
  end

  ### Test some security methods.
  ### NOTE: we do not test the term urls

  ###################### test getURLUniqname

  puts "make checks ignore extension"

  def test_getURLUniqname_courses
    s = "/StudentDashboard/courses/maggie.json"
    r = CourseList.getURLUniqname(s)
    assert_equal "maggie", r, "extract from courses url"
  end

  def test_getURLUniqname_courses_nojson
    s = "/StudentDashboard/courses/maggie"
    r = CourseList.getURLUniqname(s)
    assert_equal "maggie", r, "extract from courses url"
  end

  def test_getURLUniqname_courses_trailing_blank
    s = "/StudentDashboard/courses/maggie.json "
    r = CourseList.getURLUniqname(s)
    assert_equal "maggie", r, "extract from courses url with trailing blank"
  end

  def test_getURLUniqname_courses_trailing_slash
    s = "/StudentDashboard/courses/maggie.json/"
    r = CourseList.getURLUniqname(s)
    assert_equal "maggie", r, "extract from courses url with trailing blank"
  end

  def test_getURLUniqname_UNIQNAME
    s = "/StudentDashboard/?UNIQNAME=daisy"
    r = CourseList.getURLUniqname(s)
    assert_equal "daisy", r, "extract from UNIQNAME url"
  end

  def test_getURLUniqname_courses_termid
    s = "/StudentDashboard/courses/goby.json?TERMID=2010"
    r = CourseList.getURLUniqname(s)
    assert_equal "goby", r, "extract from courses with TERMID"
  end

  def test_getURLUniqname_todolms_json
    s = "/StudentDashboard/todolms/goby.json"
    r = CourseList.getURLUniqname(s)
    assert_equal "goby", r, "extract todolms with json"
  end

  def test_getURLUniqname_todolms_nojson
    s = "/StudentDashboard/todolms/goby"
    r = CourseList.getURLUniqname(s)
    assert_equal "goby", r, "extract todolms no json"
  end

  def test_getURLUniqname_todolms_ctools_nojson
    s = "/StudentDashboard/todolms/goby/ctools"
    r = CourseList.getURLUniqname(s)
    assert_equal "goby", r, "extract todolms ctools subsource no json"
  end

  def test_getURLUniqname_todolms_ctools_json
    s = "/StudentDashboard/todolms/goby/ctools.json"
    r = CourseList.getURLUniqname(s)
    assert_equal "goby", r, "extract todolms ctools subsource with .json"
  end

  ############################### test veto request
  ## vetoRequest takes a block to determine if the user is an admin.
  ## That makes testing much easier.

  def test_veto_request_not_admin_non_url
    r = CourseList.vetoRequest("abba", "dylan") { false }
    refute r, "unrelated url"
  end


  ## plain SD request, admin and not admin for self and other

  def test_veto_request_simple_self_not_admin
    s = "/StudentDashboard"
    r = CourseList.vetoRequest("daisy", s) { false }
    refute r, "self simple not admin"
  end

  def test_veto_request_simple_self_admin
    s = "/StudentDashboard"
    r = CourseList.vetoRequest("daisy", s) { true }
    refute r, "self simple not admin"
  end

  ##### UNIQNAME in url

  # ask for self
  def test_veto_request_uniqname_self_not_admin
    s = "/StudentDashboard/?UNIQNAME=daisy"
    r = CourseList.vetoRequest("daisy", s) { false }
    refute r, "self uniqname not admin"
  end

  def test_veto_request_uniqname_self_admin
    s = "/StudentDashboard/?UNIQNAME=daisy"
    r = CourseList.vetoRequest("daisy", s) { true }
    refute r, "self uniqname admin"
  end

  # ask for other
  def test_veto_request_uniqname_other_admin
    s = "/StudentDashboard/?UNIQNAME=dimples"
    r = CourseList.vetoRequest("daisy", s) { true }
    refute r, "uniqname other admin"
  end

  def test_veto_request_uniqname_other_not_admin
    s = "/StudentDashboard/?UNIQNAME=dimples"
    r = CourseList.vetoRequest("daisy", s) { false }
    assert r, "uniqname other not admin"
  end

  ##### courses url
  # ask for self
  def test_veto_request_courses_self_not_admin
    s="/StudentDashboard/courses/abba.json"
    r = CourseList.vetoRequest("abba", s) { false }
    refute r, "request my courses not admin"
  end

  def test_veto_request_courses_self_admin
    s="/StudentDashboard/courses/abba.json"
    r = CourseList.vetoRequest("abba", s) { true }
    refute r, "request my  courses admin"
  end

  # ask for other
  def test_veto_request_courses_other_not_admin
    s="/StudentDashboard/courses/abba.json"
    r = CourseList.vetoRequest("daisy", s) { false }
    assert r, "request other courses not admin"
  end

  def test_veto_request_courses_other_admin
    s="/StudentDashboard/courses/abba.json"
    r = CourseList.vetoRequest("abba", s) { true }
    refute r, "request my  courses admin"
  end


  def test_assemble_course_parameters
    course_ids = [43412, 44630]
    correct="&context_codes[]=course_43412&context_codes[]=course_44630"
    encoded = CourseList.course_list_string [43412, 44630]
    assert_equal correct, encoded, "multiple courses as parameters"
  end

  # check if safe_html_escape respects nil input
  def test_safe_html_escape

    ## pass in variables
    a = "HI"
    a = CourseList.safe_html_escape(a)
    assert_equal "HI",a,"return string input"

    b = nil
    b = CourseList.safe_html_escape(b)
    assert_nil b,"nil remains nil"

    ## pass in values
    b = CourseList.safe_html_escape(nil)
    assert_nil b,"nil remains nil"

    a = CourseList.safe_html_escape("HI")
    assert_equal "HI",a,"return string input"
  end


end

