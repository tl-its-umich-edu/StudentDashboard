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

  def initConfigureCToolsHTTPProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:ctools_http_application_name]
    logger.debug "#{__method__}: #{__LINE__}: configure provider CToolsHTTP: security_file: #{security_file} application_name: #{application_name}"

    @ctoolsHash = Hash.new if @ctoolsHash.nil?

    #@ctoolsHash[:useHTTPToDoLMSProvider] = true
    #@ctoolsHash[:HTTPDirectToDoLMS] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMS(uniqname, security_file, application_name) }
    @ctoolsHash[:ToDoLMSProvider] = true
    @ctoolsHash[:ToDoLMS] = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMS(uniqname, security_file, application_name) }
    @ctoolsHash
  end


  def ctoolsHTTPDirectToDoLMS(uniqname, security_file, http_application)
    logger.debug "#{__method__}: #{__LINE__}: ############### call ctools http direct todolms http_application: #{http_application}"

    http_channel = ChannelCToolsDirectHTTP.new(security_file, http_application)
    http_channel.runGetCToolsSession

    become_user = http_channel.do_request("/session/becomeuser/#{uniqname}.json")

    logger.debug "#{__method__}: #{__LINE__}: becomeuser: [#{become_user}]"
    logger.debug "#{__method__}: #{__LINE__}: becomeuser: response: "+become_user.inspect

    if /failure/i =~ become_user.to_s
      logger.debug "#{__method__}: #{__LINE__}: become user failed for user: #{uniqname}"
      return WAPIResultWrapper.new(WAPI::HTTP_NOT_FOUND, "CTools becomeuser failed for user: #{uniqname}", "{}")
    end

    ctools_todos = http_channel.do_request("/dash/calendar.json")
    logger.debug "#{__method__}: #{__LINE__}: calendar: todos: #{ctools_todos}"

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got todos from ctools direct", ctools_todos)
  end

end
