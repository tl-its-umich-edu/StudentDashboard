###### CTools direct URL provider ################
# Format the CTools direct response into json format that UI expects.

require_relative './Logging'
require 'rest-client'

# Handle interpretation and reformatting of a CTools direct call.
# The incoming data will NOT have the WAPI wrapper.

## Output format is defined in: https://docs.google.com/document/d/1KfhK6aMW1FdZdQwzTj5UO_zHq1qG6Fnpq80yWFV8hN4/edit

class CToolsDirectResponse

  # Store the body of the response.  All output from CTools direct goes through this class.
  attr_accessor :body_string, :body_json

  ## TODO: allow input as string or json

  # Input is in string format
  def initialize(body)
    @body_string = body
    @body_json = JSON.parse(body)

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

    assign
  end

  def dump
    logger.debug "#{__method__}: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{__method__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
