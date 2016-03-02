module DataProviderCToolsDirectESB

  require_relative 'WAPI_result_wrapper'
  #require_relative 'channel_ctools_direct_http'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for CTools direct data via the ESB proxy.

  ## example data URLs for ctools direct calls.
  #$P://$HOST/direct/dash/calendar.json?$SES
  #$P://$HOST/direct/session/becomeuser/$NEW_USER.json?$SES
  #curl $CURL_STD -X DELETE $P://$HOST/direct/session/$SESSION?$SES
  #$P://$HOST/direct/session.json?$SES

  def initialize
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: ######### call initialize (CTools Direct ESB)"
    super()
    @ctoolsDirectESB_w = ""
    @ctoolsDirectESB_yml = ""
    @ctoolsDirectESB_response = ""
  end

  def setupCToolsDirectESBWAPI(app_name)
    logger.info "#{self.class.to_s}:#{__method__}: #{__LINE__}: setup CTools Direct WAPI for [#{app_name}]"
    application = @ctoolsDirectESB_yml[app_name]
    logger.info "#{self.class.to_s}:#{__method__}: #{__LINE__}: application: [#{application.to_json}"
    @ctoolsDirectESB_w = WAPI.new application
  end

  def initCToolsDirectESB(security_file,app_name)
    requested_file = security_file
    default_security_file = './server/local/security.yml'
    file_name = (File.exist? requested_file ? requested_file : default_security_file)
    logger.info "#{self.class.to_s}:#{__method__}: #{__LINE__}: security_file name: [#{file_name}]"
    @ctoolsDirectESB_yml = YAML.load_file(file_name)
    setupCToolsDirectESBWAPI(app_name)
  end

  def initConfigureCToolsDirectESBProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:ctools_direct_ESB_application_name]
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: configure provider CToolsDirectESB: security_file: #{security_file} ctools_direct_ESB_application_name: #{application_name}"

    @ctoolsHash = Hash.new if @ctoolsHash.nil?

    @ctoolsHash[:CToolsDirectProvider] = true
    @ctoolsHash[:CToolsDirect] = Proc.new { |uniqname| ctoolsDirectESBToDoLMS(uniqname, security_file, application_name) }
    @ctoolsHash
  end


  def ctoolsDirectESBToDoLMS(uniqname, security_file, esb_application)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: ############### call ctools ESB direct todolms ESB_application: #{esb_application}"

    ctools_todos = @ctoolsDirecTESB_w.get_request("/dash/calendar.json")
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: calendar: todos: #{ctools_todos}"
    ctools_todo_body = ctools_todo.result
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: calendar: todos: #{ctools_todos}"
    ctools_todos_body_ruby = JSON.parse ctools_todos_body

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got todos from ctools direct esb", ctools_todos_body_ruby)
  end

end
