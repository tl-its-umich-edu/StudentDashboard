###### CTools direct URL provider ################
# Format the CTools mneme direct response into json format that UI expects.

require_relative './Logging'
require 'rest-client'

# Handle interpretation and reformatting of a CTools mneme direct call.
# The incoming data will NOT have the WAPI wrapper.

## Output format is defined in: https://docs.google.com/document/d/1KfhK6aMW1FdZdQwzTj5UO_zHq1qG6Fnpq80yWFV8hN4/edit

class MnemeAPIResponse

  # Store the body of the response.  All output from CTools direct goes through this class.
  attr_accessor :body_string, :body_json, :stringReplace

  SECONDS_PER_DAY = 60*60*24
  SECONDS_PER_WEEK = SECONDS_PER_DAY * 7

  # Input is in string format
  def initialize(body, stringReplace=Hash.new())
    @body_string = body
    @body_json = JSON.parse(body)
    @stringReplace = stringReplace

    #dump
  end

  # return the body formatted as todolms json
  def toDoLms
    collection = @body_json['mneme_collection']
    return Array.new() if collection.nil?
    # apply the extraction/reformat to each assignment and keep only those that generate some output.
    collection.map { |entry| extractAssignment(entry) }.find_all { |entry| entry }
  end

  def extractAssignment(assignment)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: assignment: [#{CourseList.limit_msg(assignment.inspect)}]"

    # make sure there is something to do.
    return nil if (assignment.nil?)

    # verify that this assignment is desired.
    return nil if filter(assignment).nil?

    # create a single assignment object in known format for UI.
    assign = Hash.new()

    # These entries have static values
    assign[:grade] = ''
    assign[:grade_type] = ''
    assign[:done] = ''
    assign[:description] = ''
    assign[:contextLMS] = 'ctools'

    # These entries get values from top level elements
    assign[:title] = assignment['title']

    assign[:due_date_sort] = self.class.standard_epoch(assignment['closeDate'])

    # These entries get values from the nested context element
    unless assignment['context'].nil?
      assign[:context] = assignment['context']['contextTitle']
      assign[:link] = assignment['context']['directToolUrl']
      assign[:contextUrl] = assignment['context']['contextUrl']
    end

    # Allow string replacement.  This is needed to ensure that host names are correct.
    @stringReplace.each_pair do |key, value|
      next if assign[key.to_sym].nil?
      from_name = @stringReplace[key][0]
      to_name = @stringReplace[key][1]
      assign[key.to_sym].gsub!(from_name, to_name)
    end

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: assign: [#{assign.inspect}]"

    assign
  end

  ############ Filter assignments
  # The filter will take a single assignment and return it if it is acceptable and return nil
  # if the assignment should not be used.

  # The checks require date comparisons. To make testing easier the actual filter is implemented as
  # a class method which requires the time as an argument.  The following instance method defaults
  # the time to the current time to now.  'now' is a method that can be overridden by tests.

  # This is an instance method to bind the time used for filtering to the current time.
  def filter(assignment)
    result = self.class.filter_out_irrelevant_assignments(assignment, now().to_i)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: skipping assignment: [#{CourseList.limit_msg(assignment.inspect)}]" unless result
    return result
  end

  # This is a class method for easy testing.  The current time must be passed in
  def self.filter_out_irrelevant_assignments(assignment, now)

    closeDate = self.standard_epoch(assignment['closeDate'])
    openDate = self.standard_epoch(assignment['openDate'])
    published = assignment['published']

    return nil unless published.equal?(true)

    return nil if openDate.nil?
    return nil unless openDate <= now

    return nil if closeDate.nil?

    # Can see assignments for a while after the close date.  Calculate
    # that cutoff.
    offset = 1*SECONDS_PER_WEEK
    closeSlack = closeDate + offset
    return nil if now > closeSlack

    assignment
  end

  # Allow overriding the current time.
  def now
    Time.now()
  end

  # convert epoch with milliseconds to epoch in seconds
  def self.standard_epoch(epoch_milliseconds)
    epoch_milliseconds.nil? ? nil : epoch_milliseconds.to_s[0..9].to_i
  end

  def dump
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
