###### CTools direct URL provider ################
# Format the CTools direct response into json format that UI expects.

require_relative './Logging'
require 'rest-client'

# Handle interpretation and reformatting of a CTools direct call.
# The incoming data will NOT have the WAPI wrapper.

## Output format is defined in: https://docs.google.com/document/d/1KfhK6aMW1FdZdQwzTj5UO_zHq1qG6Fnpq80yWFV8hN4/edit

class CanvasAPIResponse

  # Store the body of the response.  All output from Canvas API goes through this class.
  attr_accessor :body_string, :body_json

  ## TODO: allow input as string or json

  # Input is in string format
  def initialize(body)
    @body_string = body
    @body_json = JSON.parse(body)
    @canvas_instance_prefix = 'https://umich.test.instructure.com.dummy'

    #dump
  end

  # return the body formatted as todolms json
  def toDoLms
    dump
    collection = @body_json
    return Array.new() if collection.nil?

    # process all the assignments and return as a list
    collection.map { |dash_entry| extractEvent(dash_entry) }
  end

  def extractEvent(event)

    # Verify that data can be accessed.  This doesn't / shouldn't check that
    # value is not nil, just that it is possible to get the value.

   # logger.debug "#{__method__}: #{__LINE__}: canvas event: [#{event}]"

    return nil if (event.nil?)

    # create a single assignment object in known format for UI.
    standard_event = Hash.new()

    standard_event[:title] = event['title']
    standard_event[:grade] = ''
    standard_event[:done] = ''
    standard_event[:contextLMS] = 'canvas'
    standard_event[:description] = ''
    standard_event[:link] = event['html_url']
    standard_event[:contextUrl] = "http://www.newsoftheweird.com/archive/index.html"
    logger.debug "replace context url with fixed value"
    standard_event[:context] = event['context_code']
    standard_event[:id] = event['id']

    unless event['assignment'].nil?

      standard_event[:grade_type] = event['assignment']['grading_type']
      standard_event[:contextUrl] = "#{@canvas_instance_prefix}/courses/#{event['assignment']['course_id']}"

      # turn due date into standard format.  Canvas date will be in iso8601 format.
      assignment_date = event['assignment']['due_at']
      standard_event[:due_date_sort] = DateTime.parse(assignment_date).strftime('%s') unless assignment_date.nil?

    end

    # # make sure the epoch date only has 10 characters.
    # assign[:due_date_sort] = event['calendarItem']['calendarTime'].to_s[0..9]
    #
    # assign[:contextUrl] = event['calendarItem']['context']['contextUrl']
    # server = assign[:contextUrl].sub(/\/portal.*/, '')
    #
    # entity_reference = event['calendarItem']['entityReference']
    # assign[:link] = server.to_s+
    #     '/direct/assignment/deepLink/' +
    #     entity_reference.sub(/\/assignment\/a\//, '') +
    #     '.json'.to_s

    #logger.debug "#{__FILE__}:#{__method__}: #{__LINE__}: canvas standard_event: [#{standard_event}]"
    standard_event
  end

  def dump
    logger.debug "CanvasAPIResponse: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{__FILE__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
