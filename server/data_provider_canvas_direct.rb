module DataProviderCanvasDirect

  require_relative 'WAPI_result_wrapper'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for canvas direct data via the HTTP channel.
  # CURRENTLY UNIMPLEMENTED
  # TODO: example data URLs for canvas direct calls.

  def initConfigureCanvasHTTPProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:canvas_http_application_name]
    logger.debug "#{__method__}: #{__LINE__}: configure provider CanvasHTTP: security_file: [#{security_file}] application_name: [#{application_name}]"
    #logger.debug "#{__method__}: #{__LINE__}: configure provider CanvasHTTP: !!!!!!!!!! ain't nothing to do right now"

    @canvasHash = Hash.new if @canvasHash.nil?

    @canvasHash[:useToDoLMSProvider] = true
    @canvasHash[:ToDoLMS] = Proc.new { |uniqname| canvasHTTPDirectToDoLMS(uniqname, security_file, application_name) }

    @canvasHash
  end


  def canvasHTTPDirectToDoLMS(uniqname, security_file, http_application)
    logger.debug "#{__method__}: #{__LINE__}: ############### call canvas http direct todolms http_application: #{http_application}"
    logger.debug "#{__method__}: #{__LINE__}: ############### currently lying as just return empty data"

    canvas_body = "{}"
    canvas_body_ruby = JSON.parse canvas_body
    logger.debug "#{__method__}: #{__LINE__}: calendar: todos: #{canvas_body_ruby}"

    return WAPIResultWrapper.new(WAPIStatus::SUCCESS, "got todos from canvas direct", canvas_body_ruby)
  end

end
