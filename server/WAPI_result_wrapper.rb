require_relative './Logging'
require 'json'

include Logging
class WAPIResultWrapper

  def initialize(status, msg, result)
    @value = Hash['Meta' => Hash['httpStatus' => status,
                                 'Message' => msg],
                  'Result' => result]
    @value
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

  # allow reconstructing a wrapper when the result comes from
  # a json string.
  def setValue(value)
    @value = value
  end

  def self.value_from_json(json_string)
    ## Wrap the json in the file as the result of the query.
    wr = WAPIResultWrapper.new(200, "dummy msg", "dummy result")
    #w = JSON.parse(json_string)
    #logger.debug("WAPI_vfj w: #{__LINE__}: value_from_json result: "+w.inspect)
    wr.setValue(JSON.parse(json_string))
    wr
  end

  # Turn the value of result into json if it is json
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

end
