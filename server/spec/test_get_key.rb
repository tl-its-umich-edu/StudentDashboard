#require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
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
}]'


# get hash values for all nested hashs that have this key.
  def getValues(key, obj)
    #puts"call: key: [#{key}] object: [#{obj}]"
    #puts"call: key.inspect: [#{key.inspect}]"
    values = []
    case obj
#      when String
#        puts "got string: [#{obj.inspect}]"
#        return obj
      when Array
        #puts"array: obj.inspect: #{obj.inspect}"
        values = obj.flat_map { |o| getValues(key, o) }
      when Hash
        #puts"hash: obj.inspect: #{obj.inspect}"
        #puts"hash: keys: #{obj.keys().inspect}"
        obj.each_pair do |k, v|
          #puts"hash: pair: [#{k}]:[#{v}]"
          #if obj.has_key?(key) then
          #  puts"hash contains this key: [#{key}]"
          #end
          #if obj.has_key?(k) then
          #puts "k: [#{k}] key: [#{key}]"
          if k === key then
#            puts"adding k: [#{k}] v: [#{v}]"
            values.push(v)
            #values.push(getValues(k,v))
          else
 #           puts "key did not match"
            values.push(getValues(key, v))
  #          puts "recursed values: #{values}"
          end
        end
        #puts"hash: values: #{values.inspect}"
        test_val = values.flat_map
        #puts"getValues: #{test_val.inspect}"
        values.flatten!
      else # not array or hash
        values = []
    end

    #puts"FINAL VALUES: #{values.inspect}"
    values
  end

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
    assert_equal correct, getValues('Title', JSON.parse(@@test_one)),"extract title"
  end

  def test_link
    correct = ["https : //umi ch.test.instructure.com/courses/43412"]
    assert_equal correct, getValues('Link', JSON.parse(@@test_one)),"extract link url"
  end

  def test_days
    correct = ["Mo"]
    assert_equal correct, getValues('Days', JSON.parse(@@test_one)),"extract meetings days"
  end

  def test_macho_man
    correct = []
    assert_equal correct, getValues('macho_man', JSON.parse(@@test_one)),"do not find macho_man"
  end

end
