require_relative './Logging'
require 'json'

include Logging
class WAPIResultWrapper

  def initialize(status, msg, result)
    @value = Hash['Meta' => Hash['httpStatus' => status,
                                 'Message' => msg],
                  'Result' => result]
  end

  def meta_status
    @value['Meta']['httpStatus']
  end

  def meta_message
    @value['Meta']['Message']
  end

  def result
    @value['Result']
  end

  def value
    @value
  end

  # Check if this is a valid wrapper.  Setting the contents
  # directly would allow creating a wrapper with invalid contents.
  def valid?
    begin
      return true if @value.has_key?("Meta")
    rescue
      logger.warn "invalid WAPI wrapper:  " +self.to_s
    end
    nil
  end

  # allow setting the internal hash value of the wrapper directly.
  # This completely replaces the existing contents.
  def setValue(value)
    @value = value
  end

  # Take the json version of wrapped data and return a
  # reconstituted ruby object.
  def self.value_from_json(json_string)
    # create a new wrapper
    wr = WAPIResultWrapper.new(200, "dummy msg", "dummy result")
    # set the content of the wrapper to the parsed contents of the json string.
    wr.setValue(JSON.parse(json_string))
    wr
  end

  # Turn the value of the result field into json if it is parseable as json
  def value_as_json
    c = @value.dup
    new_result = c['Result'].dup
    ## see if can tread new_result as json
    begin
      new_result = JSON.parse(new_result)
    rescue Exception => e
      # If there is a problem then just forget about the attempt to make it json
    end
    c['Result'] = new_result
    c.to_json
  end

  # Return the hash as a json string.
  #def to_json
#    puts "to_json"
#    p @value
#    @value.to_json
#  end

end
