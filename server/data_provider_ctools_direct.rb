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

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{@ctoolsHash.inspect}]"
    return @ctoolsHash unless @ctoolsHash[:ToDoLMSProviderDash].nil?

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{@ctoolsHash.inspect}]"

    ## setup the dashboard query
    @ctoolsHash[:ToDoLMSProviderDash] = true
    @ctoolsHash[:ToDoLMSDash] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMSDash(uniqname, security_file, application_name) }
    @ctoolsHash[:formatResponseCToolsDash] = Proc.new { |body| CToolsDirectResponse.new(body,stringReplace) }

    ## setup the mneme query
    @ctoolsHash[:ToDoLMSProviderMneme] = true
    @ctoolsHash[:ToDoLMSMneme] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMSMneme(uniqname, security_file, application_name) }
    @ctoolsHash[:formatResponseCToolsMneme] = Proc.new { |body| MnemeAPIResponse.new(body,stringReplace) }

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{@ctoolsHash.inspect}]"

    @ctoolsHash
  end

  ### Method to get result from the CTools direct Dashboard calendar

  def ctoolsHTTPDirectToDoLMSDash(uniqname, security_file, http_application)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ############### call ctools http direct Dash todolms http_application: #{http_application}"

    http_channel = ChannelCToolsDirectHTTP.new(security_file, http_application)
    http_channel.runGetCToolsSession

    become_user = http_channel.do_request("/session/becomeuser/#{uniqname}.json")

    logger.debug "#{__method__}: #{__LINE__}: becomeuser: [#{become_user}]"
    logger.debug "#{__method__}: #{__LINE__}: becomeuser: response: "+become_user.inspect

    if /failure/i =~ become_user.to_s
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: become user failed for user: #{uniqname}"
      return WAPIResultWrapper.new(WAPI::HTTP_NOT_FOUND, "CTools becomeuser failed for user: #{uniqname}", "{}")
    end

    ctools_todos = http_channel.do_request("/dash/calendar.json")

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got dash todos from ctools direct", ctools_todos)
  end


  ## Method to get result from CTools direct mneme feed.
  def ctoolsHTTPDirectToDoLMSMneme(uniqname, security_file, http_application)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ############### call ctools http direct Mneme todolms http_application: #{http_application}"

    http_channel = ChannelCToolsDirectHTTP.new(security_file, http_application)
    http_channel.runGetCToolsSession

    become_user = http_channel.do_request("/session/becomeuser/#{uniqname}.json")

    logger.debug "#{__method__}: #{__LINE__}: becomeuser: [#{become_user}]"
    logger.debug "#{__method__}: #{__LINE__}: becomeuser: response: "+become_user.inspect

    if /failure/i =~ become_user.to_s
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: become user failed for user: #{uniqname}"
      return WAPIResultWrapper.new(WAPI::HTTP_NOT_FOUND, "CTools becomeuser failed for user: #{uniqname}", "{}")
    end

    #/direct/mneme/my
    ctools_todos = http_channel.do_request("/mneme/my.json")

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got mneme todos from ctools direct", ctools_todos)
  end

end
