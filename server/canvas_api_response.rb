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

  # input should be converted to json string.
  def initialize(body, stringReplace)
    body = body.to_json
    @body_string = body
    @body_json = JSON.parse(body)
    # specifies strings to be replaced.  The replacement is only done
    # in specific elements.
    @stringReplace = stringReplace
  end

  # return the body formatted as todolms json
  def toDoLms
    #dump
    collection = @body_json
    return Array.new() if collection.nil?

    # process all the assignments and return as a list
    collection.map { |dash_entry| extractEvent(dash_entry) }
  end

  def extractEvent(event)

    # Verify that data can be accessed.
    return nil if (event.nil?)

    # create a single assignment object in known format for UI.
    standard_event = Hash.new()

    standard_event[:title] = event['title']
    standard_event[:grade] = ''
    standard_event[:done] = ''
    standard_event[:contextLMS] = 'canvas'
    standard_event[:description] = ''
    standard_event[:link] = event['html_url']
    standard_event[:contextUrl] = "CANVAS_INSTANCE_PREFIX"
    standard_event[:context] = event['context_code']
    standard_event[:id] = event['id']

    unless event['assignment'].nil?

      standard_event[:grade_type] = event['assignment']['grading_type']
      ## the PREFIX will be replaced by the correct value in the replace below.
      standard_event[:contextUrl] = "CANVAS_INSTANCE_PREFIX/courses/#{event['assignment']['course_id']}"

      # turn due date into standard format.  Canvas date will be in iso8601 format.
      assignment_date = event['assignment']['due_at']
      standard_event[:due_date_sort] = DateTime.parse(assignment_date).strftime('%s') unless assignment_date.nil?

      ## Allow fake dates for some testing
      #logger.error "#{self.class.to_s}:#{__method__}:#{__LINE__}: FAKE DATE FOR CANVAS";
      #      standard_event[:due_date_sort] = Time.now().to_i


    end

    # Allow string replacement.  This is needed to ensure that host names are correct.
    # See studentdashboard.yml.TXT for information.
    @stringReplace.each_pair do |key, value|
      next if standard_event[key.to_sym].nil?
      from_name = @stringReplace[key][0]
      to_name = @stringReplace[key][1]
      standard_event[key.to_sym].gsub!(from_name, to_name)
      logger.debug "#{__FILE__}: #{__LINE__}: possible update for #{standard_event[key.to_sym]}"
    end

    standard_event
  end

  def dump
    logger.debug "#{__FILE__}: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{__FILE__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
