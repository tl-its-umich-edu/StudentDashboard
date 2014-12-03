require_relative './Logging'
require 'json'

include Logging
class WAPIResultWrapper

  def initialize(status, msg, result)
    @value = Hash['Meta' => Hash['httpStatus' => status,
                                 'Message' => msg],
                  'Result' => result]
    logger.debug("WAPI_r_w: #{__LINE__}: created wrapped_result: "+@value.inspect)
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

  # Return the value as json.  Turn the value of result into json
  # if that is value.
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


  # def valid_json?(json)
  #   begin
  #     JSON.parse(json)
  #     return true
  #   rescue Exception => e
  #     return false
  #   end
  # end

end
