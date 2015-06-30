## Unit tests for provider esb module

require_relative 'test_helper'

require 'rubygems'

require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'webmock/minitest'
require_relative '../data_provider_esb'
require 'logger'
require_relative '../../server/Logging'
require_relative '../WAPI'


# Test parsing of potential results from ESB.  Tests concentrate
# on parsing the JSON.

class TestProviderESB < MiniTest::Test
  include Logging

  ## test data
  @@classDataA = {
      "Meta" => {
          "httpStatus" => 200,
          "Message" => "found value getMyClsScheduleResponse:RegisteredClasses from ESB"
      },
      "Result" => [
          {
              "Title" => "COMPLIT 100",
              "Subtitle" => "Global X",
              "SectionNumber" => "001",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  {
                      "Name" => "Colas,Santiago",
                      "Role" => "Primary Instructor",
                      "Email" => "SCOLAS@umich.edu"
                  },
                  {
                      "Name" => "Reveria,Santiago Inmpira",
                      "Role" => "Primary Instructor and way cool",
                      "Email" => "SIR@nowhere.edu"
                  },
              ]
          },
          {
              "Title" => "COMPLIT 100",
              "Subtitle" => "Global X",
              "SectionNumber" => "004",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  nil
              ]
          },
          {
              "Title" => "EECS 183",
              "Subtitle" => "Elem Prog Concepts",
              "SectionNumber" => "004",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  {
                      "Name" => "Darden,Marcus M",
                      "Role" => "Primary Instructor",
                      "Email" => "MMDARDEN@umich.edu"
                  }
              ]
          },
          {
              "Title" => "EECS 183",
              "Subtitle" => "Elem Prog Concepts",
              "SectionNumber" => "030",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  nil
              ]
          },
          {
              "Title" => "MATH 116",
              "Subtitle" => "Calculus II",
              "SectionNumber" => "019",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  nil
              ]
          },
          {
              "Title" => "PSYCH 112",
              "Subtitle" => "Psy as Natl Science",
              "SectionNumber" => "001",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  {
                      "Name" => "Malley,Brian",
                      "Role" => "Primary Instructor",
                      "Email" => "BMALLEY@umich.edu"
                  }
              ]
          },
          {
              "Title" => "PSYCH 112",
              "Subtitle" => "Psy as Natl Science",
              "SectionNumber" => "012",
              "Source" => nil,
              "Link" => nil,
              "Instructor" => [
                  nil
              ]
          }
      ]
  };

  def setup
    # by default assume the tests will run well and don't
    # need detailed log messages.
    logger.level=Logger::ERROR
    #logger.level=Logger::DEBUG

    # create class to test module
    @m = Class.new do
      include DataProviderESB
      include Logging
    end.new
  end

  def test_new_creates_something
    refute_nil @m
  end

  def test_esb_terms_null
    # fix null entry
    h = '{"getMyRegTermsResponse":null}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::SUCCESS, t.meta_status, 'ESB returned value was null, we make it empty array')
    assert_equal(0, t.result.length, "empty array")
  end

  def test_esb_terms_nil
    # this is an error because it isn't valid json
    h = '{"getMyRegTermsResponse":nil}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::UNKNOWN_ERROR, t.meta_status, 'ESB returned value was nil, which is not valid json')
  end

  def test_esb_terms_empty_string
    # make empty string into empty array
    h = '{"getMyRegTermsResponse":""}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::SUCCESS, t.meta_status, 'ESB returned value was empty string, we make it empty array')
    assert_equal(0, t.result.length, "empty array")
  end

  def test_esb_parse_terms_good
    # make sure valid term is ok
    h = '{"getMyRegTermsResponse":{"Term":[{"TermCode":"2020","TermDescr":"Winter 2015","TermShortDescr":"WN 2015"}]}}'
    t = @m.parseESBData(h, DataProviderESB::TERM_REG_KEY, DataProviderESB::TERM_KEY)
    assert_equal(WAPI::SUCCESS, t.meta_status, 'ESB returned value was good')
  end

  ## Ruby big hammer way of making a deep copy of an object.
  def deepCopy(o)
    Marshal.load(Marshal.dump(o))
  end

  # utility function to access class information
  def getInstructorList (o, offset)
    o['Result'][offset]['Instructor']
  end

  def test_traverse_fix_array_with_only_nil
    # This is based on the data above
    testObj = deepCopy(@@classDataA)
    @m.fixArrayWithNilInPlace! testObj
    # make sure there are still some instructors somewhere
    assert_equal 2, getInstructorList(testObj, 0).length
    # make sure original had something in instructor array
    assert_equal 1, getInstructorList(@@classDataA, 1).length
    # make sure that it was removed.
    assert_equal 0, getInstructorList(testObj, 1).length
  end

end
