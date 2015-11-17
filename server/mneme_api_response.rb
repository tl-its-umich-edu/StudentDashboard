###### CTools direct URL provider ################
# Format the CTools direct response into json format that UI expects.

require_relative './Logging'
require 'rest-client'

# Handle interpretation and reformatting of a CTools direct call.
# The incoming data will NOT have the WAPI wrapper.

## Output format is defined in: https://docs.google.com/document/d/1KfhK6aMW1FdZdQwzTj5UO_zHq1qG6Fnpq80yWFV8hN4/edit

class MnemeAPIResponse

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
    #logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: body_string: [#{@body_string}]"
    #return @body_json
    collection = @body_json['mneme_collection']
    return Array.new() if collection.nil?
    # process all the assignments.
    collection.map { |entry| extractAssignment(entry) }
  end

  def extractAssignment(assignment)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: assignment: [#{assignment}]"
#    return assignment

    # make sure there is something to do.
    return nil if (assignment.nil?)

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
    # make sure epoch time is in seconds, not milliseconds
    closeDate = assignment['closeDate']
    assign[:due_date_sort] = closeDate.nil? ? '' : closeDate.to_s[0..9]

    # These entries get values from the nested context element
    unless assignment['context'].nil?
      assign[:context] = assignment['context']['contextTitle']
      assign[:link] = assignment['context']['directToolUrl']
      assign[:contextUrl] = assignment['context']['contextUrl']
    end

   # Allow string replacement.  This is needed to ensure that host names are correct.
   # See studentdashboard.yml.TXT for information.
    @stringReplace.each_pair do |key,value|
      next if assign[key.to_sym].nil?
      from_name = @stringReplace[key][0]
      to_name = @stringReplace[key][1]
      assign[key.to_sym].gsub!(from_name,to_name)
      logger.debug "#{__FILE__}: #{__LINE__}: possible update for #{assign[key.to_sym]}"
    end

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: assign: [#{assign.inspect}]"

    assign
  end

  def dump
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: body_string: [#{@body_string}]"
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: body_json: [#{@body_json}]"
  end

end
