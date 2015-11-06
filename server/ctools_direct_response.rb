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
  def initialize(body,stringReplace)
    @body_string = body
    @body_json = JSON.parse(body)

    @stringReplace = stringReplace
    #dump
  end

  # return the body formatted as todolms json
  def toDoLms
    collection = @body_json['dash_collection']
    return Array.new() if collection.nil?
    # process all the assignments.
    collection.map { |dash_entry| extractAssignment(dash_entry) }
  end

  def extractAssignment(assignment)

    # Verify that data can be accessed.  This doesn't / shouldn't check that
    # value is not nil, just that it is possible to get the value.
    return nil if (assignment.nil?)
    return nil if (assignment['calendarItem'].nil?)
    return nil if (assignment['calendarItem']['context'].nil?)

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
    assign[:link] = server.to_s+
        '/direct/assignment/deepLink/' +
        entity_reference.sub(/\/assignment\/a\//, '') +
        '.json'.to_s

    # Allow string replacement.  This is needed to ensure that host names are correct.
    # See studentdashboard.yml.TXT for information.
    @stringReplace.each_pair do |key,value|
      next if assign[key.to_sym].nil?
      from_name = @stringReplace[key][0]
      to_name = @stringReplace[key][1]
      assign[key.to_sym].gsub!(from_name,to_name)
      logger.debug "#{__FILE__}: #{__LINE__}: possible update for #{assign[key.to_sym]}"
    end

    assign
  end

  def dump
    logger.debug "#{__method__}: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{__method__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
