###### CTools direct URL provider ################
# Format the CTools direct response into json format that UI expects.

require_relative './Logging'
require 'rest-client'

# Handle interpretation and reformatting of a CTools direct call.
# The incoming data will NOT have the WAPI wrapper.

## Output format is defined in: https://docs.google.com/document/d/1KfhK6aMW1FdZdQwzTj5UO_zHq1qG6Fnpq80yWFV8hN4/edit

class CToolsDirectResponse

  # Store the body of the response.  All output from CTools direct goes through this class.
  attr_accessor :body_string, :body_json, :stringReplace

  ## TODO: allow input as string or json

  # Input is in string format
  def initialize(body, stringReplace)
    @body_string = body
    @body_json = JSON.parse(body)

    @stringReplace = stringReplace
    #dump
  end

  # return the body formatted as todolms json
  def toDoLms
    collection = @body_json['dash_collection']
    return Array.new() if collection.nil?

    # apply the extraction/reformat to each assignment and keep only those that generate some output.
    collection.map { |entry| extractAssignment(entry) }.find_all { |entry| entry }
  end

  def extractAssignment(assignment)

    # Verify that data can be accessed.  This doesn't / shouldn't check that
    # value is not nil, just that it is possible to get the value.
    return nil if (assignment.nil?)
    return nil if (assignment['calendarItem'].nil?)
    return nil if (assignment['calendarItem']['context'].nil?)

    # verify that this assignment is desired.
    return nil if self.class.filter(assignment).nil?

    # create a single assignment object in known format for UI.
    assign = Hash.new()

    assign[:title] = assignment['calendarItem']['title']
    assign[:grade] = ''
    assign[:done] = ''
    assign[:context] = assignment['calendarItem']['context']['contextTitle']
    assign[:contextLMS] = 'ctools'
    assign[:description] = ''

    # make sure the epoch date only has 10 characters.
    assign[:due_date_sort] = assignment['calendarItem']['calendarTime'].to_s[0..9]

    assign[:contextUrl] = assignment['calendarItem']['context']['contextUrl']
    server = assign[:contextUrl].sub(/\/portal.*/, '')

    entity_reference = assignment['calendarItem']['entityReference']
    assign[:link] = assignment['calendarItem']['infoLinkURL']

    # Allow string replacement.  This is needed to ensure that host names are correct.
    # See studentdashboard.yml.TXT for information.
    @stringReplace.each_pair do |key, value|
      next if assign[key.to_sym].nil?
      from_name = @stringReplace[key][0]
      to_name = @stringReplace[key][1]
      assign[key.to_sym].gsub!(from_name, to_name)
      logger.debug "#{__FILE__}: #{__LINE__}: possible update for #{assign[key.to_sym]}"
    end

    assign
  end

  # Take the raw assignment value and check to see if it should be filtered out.  Return the
  # assignment if acceptable and nil otherwise.
  # only accept assignments with calendar item label key of assignment.due.date
  #"calendarItem": {
  #"calendarTimeLabelKey": "assignment.due.date"

  # Make static method since it requires only local data and that's easier for testing.
  def self.filter(assignment)

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: assignment: [#{assignment.inspect}]"
    calendarItem = assignment['calendarItem']

    if calendarItem.nil?
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: assignment: fail for nil calendarItem"
      return nil
    end

    calendarTimeLabelKey = calendarItem['calendarTimeLabelKey']
    if calendarTimeLabelKey.nil?
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: assignment: fail for nil calendarTimeLabelKey"
      return nil
    end

    if 'assignment.due.date'.casecmp(calendarTimeLabelKey) != 0
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: assignment: fail for bad key: [#{calendarTimeLabelKey}]"
      return nil
    end

    assignment
  end

  def dump
    logger.debug "#{__method__}: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{__method__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
