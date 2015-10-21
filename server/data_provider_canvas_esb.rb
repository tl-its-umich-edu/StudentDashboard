module DataProviderCanvasESB

  require_relative 'WAPI_result_wrapper'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for canvas data via ESB
    #/users/self/upcoming_events?as_user_id=sis_login_id:studenta

  # initialize variables local to this access method
  def initialize
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ####### call super from initialize (CanvasESB)"
    super()
    @canvasESB_w = ""
    @canvasESB_yml = ""
  end

  ## Make a WAPI connection object.
  def setupCanvasWAPI(app_name)

    logger.info "setupCanvasAPI: canvasESB: use ESB application: #{app_name}"
    logger.debug "#{__method__}: #{__LINE__}: @canvasESB_yml: [#{@canvasESB_yml.to_json}]"
    application = @canvasESB_yml[app_name]
    logger.debug "#{__method__}: #{__LINE__}: canvasESB: use ESB application: #{application.to_json}"
    @canvasESB_w = WAPI.new application

  end

  # get the credentials for the WAPI connection
  def initCanvasESB(security_file, app_name)

    requested_file = security_file

    default_security_file = './server/local/security.yml'

    if File.exist? requested_file
      file_name = requested_file
    else
      file_name = default_security_file
    end

    logger.info "init_ESB: use security file_name: #{file_name}"
    #@@yml = YAML.load_file(file_name)
    @canvasESB_yml = YAML.load_file(file_name)
    setupCanvasWAPI(app_name)
  end


  # Setup the environment to call this provider
  def initConfigureCanvasESBProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:canvas_esb_application_name]
    logger.error "@@@@@@@@@@@@@@@@@@@@ need canvas_esb_application_name!" if application_name.nil?
    logger.debug "#{__method__}: #{__LINE__}: configure provider CanvasESB: security_file: [#{security_file}] application_name: [#{application_name}]"

    @canvasHash = Hash.new if @canvasHash.nil?

    @canvasHash[:useToDoLMSProvider] = true
    @canvasHash[:ToDoLMS] = Proc.new { |uniqname| canvasESBToDoLMS(uniqname, security_file, application_name) }
    initCanvasESB security_file, application_name
    @canvasHash
  end

  #  <canvas server>/api/v1/users/self/upcoming_events
  # actually call out to canvas and return the value.  Caller will reformat if necessary.
  def canvasESBToDoLMS(uniqname, security_file, esb_application)
    logger.debug "#{__method__}: #{__LINE__}: ############### call canvas ESB todolms esb_application: #{esb_application}"
    logger.debug "#{__method__}: #{__LINE__}: canvas ESB: @w: [#{@w}]"

    logger.error "#{__method__}: #{__LINE__}: ############## canvas ESB: use real user"
    r = @canvasESB_w.get_request "/users/self/upcoming_events?as_user_id=sis_login_id:#{uniqname}"
    logger.debug "#{self.class.name.to_s}:#{__method__}: #{__LINE__}: canvas ESB: r.inspect: [#{r.inspect}]"
    canvas_body = r.result
    canvas_body_ruby = JSON.parse canvas_body
    logger.debug "#{__method__}: #{__LINE__}: calendar: todos: #{canvas_body_ruby}"

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got todos from canvas esb", canvas_body_ruby)
  end

end
