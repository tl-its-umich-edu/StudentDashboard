#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require_relative '../courselist'
# require 'webmock/minitest'

require 'JSON'


class
TestGetValues < Minitest::Test
#https://stackoverflow.com/questions/19947956/ruby-recursive-map-of-a-hash-of-objects


  @@test_one = '[{
               "Title":"DENTHYG 209",
   "Subtitle":"Basic Radiography",
   "SectionNumber":"001",
   "Source":"Canvas",
   "Link":"https : //umi ch.test.instructure.com/courses/43412",
   "Meeting": [{
                    "MeetingNumber": 1,
   "Days":"Mo",
   "Times":"10 : 00 AM - 12 : 00 PM",
   "StartDate":"01/06/2016",
   "EndDate":"04/18/2016",
   "Location":"TBA",
   "TopicDescr": []
}]
}]'

  @@test_two = '[{
               "Title":"DENTHYG 209",
   "Subtitle":"Basic Radiography",
   "SectionNumber":"001",
   "Source":"Canvas",
   "Link":"https : //umi ch.test.instructure.com/courses/43412",
   "Meeting": [{
                    "MeetingNumber": 1,
   "Days":"Mo",
   "Times":"10 : 00 AM - 12 : 00 PM",
   "StartDate":"01/06/2016",
   "EndDate":"04/18/2016",
   "Location":"TBA",
   "TopicDescr": []
}],
   "Instructor": [{
                       "Name":"Benavides, Erika",
   "Role":"Primary Instructor",
   "Email":"BENAVID @umich.edu"
}]
},
{
               "Title":"DENTHYG 209",
   "Subtitle":"Basic Radiography",
   "SectionNumber":"001",
   "Source":"Canvas",
   "Link":"https : //umi ch.test.instructure.com/courses/43412",
   "Meeting": [{
                    "MeetingNumber": 1,
   "Days":"Mo",
   "Times":"10 : 00 AM - 12 : 00 PM",
   "StartDate":"01/06/2016",
   "EndDate":"04/18/2016",
   "Location":"TBA",
   "TopicDescr": []
}],
   "Instructor": [{
                       "Name":"Benavides, Erika",
   "Role":"Primary Instructor",
   "Email":"BENAVID @umich.edu"
}]
}
]'

# Called before every test method runs. Can be used
# to set up fixture information.
  def setup
    # Do nothing
  end

# Called after every test method runs. Can be used to tear
# down fixture information.

  def teardown
    # Do nothing
  end

  def test_title
    correct = ["DENTHYG 209"]
    assert_equal correct, CourseList.getValuesForKey('Title', JSON.parse(@@test_one)), "extract title"
  end

  def test_link
    correct = ["https : //umi ch.test.instructure.com/courses/43412"]
    assert_equal correct, CourseList.getValuesForKey('Link', JSON.parse(@@test_one)), "extract link url"
  end

  def test_days
    correct = ["Mo"]
    assert_equal correct, CourseList.getValuesForKey('Days', JSON.parse(@@test_one)), "extract meetings days"
  end

  def test_macho_man
    correct = []
    assert_equal correct, CourseList.getValuesForKey('macho_man', JSON.parse(@@test_one)), "do not find macho_man"
  end

  def test_link_2
    assert_equal 2,  CourseList.getValuesForKey('Link', JSON.parse(@@test_two)).length, "extract two link urls"
  end


end
