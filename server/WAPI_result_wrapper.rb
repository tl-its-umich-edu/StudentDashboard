require_relative './Logging'
require 'json'
require_relative './WAPI_status'

include Logging

# Wrap the result of a call made by WAPI so that caller can ALWAYS rely on there being a return
# value for the call even if there was an external problem with the call.
# This wrapper is a hash with two keys:
# 'Meta' - This hash entry is also a hash that has information about the execution of the call.  The 'More' entry
# contains the link header url to more information if the response contained partial results.
# 'Result' - This entry contains the data from the external call if the call was made successfully.

class WAPIResultWrapper

  def initialize(status, msg, result, more="")
    @value = Hash['Meta' => Hash['httpStatus' => status,
                                 'Message' => msg,
                                 'More' => more],
                  'Result' => result]
  end

  def meta_status
    @value['Meta']['httpStatus']
  end

  def meta_message
    @value['Meta']['Message']
  end

  def meta_more
    @value['Meta']['More']
  end

  # For debugging
  def meta
    @value['Meta']
  end

  # The value of the more url may need to change from the value from the external query url to one that makes sense as
  # a Dashboard url.
  def meta_more_update(updated)
    @value['Meta']['More'] = updated
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
      logger.warn "#{self.class.to_s}:#{__method__}:#{__LINE__}: invalid WAPI wrapper:  #{self.to_s}"
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
    wr = WAPIResultWrapper.new(WAPIStatus::SUCCESS, "dummy msg", "dummy result")
    # set the content of the wrapper to the parsed contents of the json string.
    begin
      wr.setValue(JSON.parse(json_string))
    rescue
      wr = WAPIResultWrapper.new(WAPIStatus::UNKNOWN_ERROR, "dummy msg", "error json parsing #{json_string}")
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: WAPI_wrapper: error parsing as json: #{json_string}"
    end

    wr
  end

  # Turn the value of the result field into json if it is parseable as json
  def value_as_json
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: WAPI_wrapper: value_as_json: " + @value.inspect
    c = @value.dup
    # Make sure Result has a non-nil value
    c['Result'] = "" unless c['Result']
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

  # An external request that returns a lot of information may return partial results and a 'link' header which
  # has an URL to request more information.  This method merges the results from two wrappers into a single one
  # This assumes that both wrappers contain valid JSON result data.
  def append_json_results(second_wrapper)

    primary_result_as_ruby = JSON.parse(self.result)
    second_result_as_ruby = JSON.parse(second_wrapper.result)
    merged_result = primary_result_as_ruby + second_result_as_ruby

    # The second request might have an URL to point at even more data, so preserve the 'More' url from that wrapper.
    WAPIResultWrapper.new(meta_status, "Merged wapi results", JSON.generate(merged_result), second_wrapper.meta_more)

  end

end
