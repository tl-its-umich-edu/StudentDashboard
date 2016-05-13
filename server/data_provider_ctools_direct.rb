module DataProviderCToolsDirect

  require_relative 'WAPI_result_wrapper'
  require_relative 'channel_ctools_direct_http'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for CTools direct data via the HTTP channel.

  ## example data URLs for ctools direct calls.
  #$P://$HOST/direct/dash/calendar.json?$SES
  #$P://$HOST/direct/session/becomeuser/$NEW_USER.json?$SES
  #curl $CURL_STD -X DELETE $P://$HOST/direct/session/$SESSION?$SES
  #$P://$HOST/direct/session.json?$SES

  ### Setup to call CTools direct api via HTTP
  def initConfigureCToolsHTTPProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:ctools_http_application_name]

    # This is hash with string replacement values.
    if !config_hash[application_name].nil? && !config_hash[application_name]['string-replace'].nil? then
      stringReplace = config_hash[application_name]['string-replace']
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: stringReplace [#{stringReplace.inspect}]"
    else
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: No string-replace specified for ctools direct application: [#{application_name}].  Supplying empty one."
      stringReplace = Hash.new()
    end

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider CToolsHTTP: security_file: #{security_file} application_name: #{application_name}"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider CToolsHTTP: string-replace: #{stringReplace.inspect}"

    @ctoolsHash = Hash.new if @ctoolsHash.nil?

    return @ctoolsHash unless @ctoolsHash[:ToDoLMSProviderDash].nil?

    ## setup the dashboard query
    @ctoolsHash[:ToDoLMSProviderDash] = true
    @ctoolsHash[:ToDoLMSDash] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMSDash(uniqname, security_file, application_name) }
    @ctoolsHash[:formatResponseCToolsDash] = Proc.new { |body| CToolsDirectResponse.new(body, stringReplace) }

    ## setup the past dashboard query
    @ctoolsHash[:ToDoLMSProviderDashPast] = true
    @ctoolsHash[:ToDoLMSDashPast] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMSPastDash(uniqname, security_file, application_name) }
    @ctoolsHash[:formatResponseCToolsDashPast] = Proc.new { |body| CToolsDirectResponse.new(body, stringReplace) }

    ## setup the mneme query
    @ctoolsHash[:ToDoLMSProviderMneme] = true
    @ctoolsHash[:ToDoLMSMneme] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMSMneme(uniqname, security_file, application_name) }
    @ctoolsHash[:formatResponseCToolsMneme] = Proc.new { |body| MnemeAPIResponse.new(body, stringReplace) }

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{CourseList.limit_msg(@ctoolsHash.inspect)}]"

    @ctoolsHash
  end

  ### Method to become the appropriate CTools user.  If the becomeuser fails
  ### it returns a WAPIResultWrapper object.

  def become_ctools_user(http_application, security_file, uniqname)

    ## setup a session in ctools as admin.
    http_channel = ChannelCToolsDirectHTTP.new(security_file, http_application)
    http_channel.runGetCToolsSession

    # become the specific user.
    become_user = http_channel.do_request("/session/becomeuser/#{uniqname}.json")

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: becomeuser: response: "+become_user.inspect

    # if it didn't work then return that information in a WAPI wrapper.
    if /failure/i =~ become_user.to_s
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: become user failed for user: #{uniqname}"
      become_user = WAPIResultWrapper.new(WAPIStatus::HTTP_NOT_FOUND, "CTools becomeuser failed for user: #{uniqname}", "{}")
    end

    return become_user, http_channel
  end

  ### run a CTools request and return the wrapped result.
  def run_ctools_direct_request(http_application, request_string, security_file, uniqname)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: request_string: #{request_string}"

    become_user, http_channel = become_ctools_user(http_application, security_file, uniqname)
    # If the result is already wrapped it is an error.
    return become_user if become_user.is_a? WAPIResultWrapper

    ctools_todos = http_channel.do_request(request_string)

    return WAPIResultWrapper.new(WAPIStatus::SUCCESS, "got dash todos from ctools direct", ctools_todos)
  end

  ########################## get data from CTools.
  ### get the Sakai dashboard future events.
  def ctoolsHTTPDirectToDoLMSDash(uniqname, security_file, http_application)
    request_string = "/dash/calendar.json"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: # ctools direct request: #{request_string}"
    return run_ctools_direct_request(http_application, request_string, security_file, uniqname)
  end

  ### get the Sakai dashboard past events
  def ctoolsHTTPDirectToDoLMSPastDash(uniqname, security_file, http_application)
    request_string = "/dash/calendar.json?past=true"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: # ctools direct request: #{request_string}"
    return run_ctools_direct_request(http_application, request_string, security_file, uniqname)
  end

  ### Get the CTools mneme events.
  def ctoolsHTTPDirectToDoLMSMneme(uniqname, security_file, http_application)
    request_string = "/mneme/my.json"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: # ctools direct request: #{request_string}"
    return run_ctools_direct_request(http_application, request_string, security_file, uniqname)
  end

end
