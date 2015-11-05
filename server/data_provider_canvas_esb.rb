module DataProviderCanvasESB

  require_relative 'WAPI_result_wrapper'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for canvas data via ESB
  # e.g. /users/self/upcoming_events?as_user_id=sis_login_id:studenta

  # initialize variables local to this access method
  def initialize
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ####### call super from initialize (CanvasESB)"
    super()
    @canvasESB_w = ""
    @canvasESB_yml = ""
    @canvasESB_response = ""
  end

  ## Make a WAPI connection object.
  def setupCanvasWAPI(app_name)

    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: setupCanvasAPI: canvasESB: use ESB application: #{app_name}"
    #logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @canvasESB_yml: [#{@canvasESB_yml.to_json}]"
    application = @canvasESB_yml[app_name]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvasESB: use ESB application: #{application.to_json}"
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

    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: init_ESB: use security file_name: #{file_name}"
    @canvasESB_yml = YAML.load_file(file_name)
    setupCanvasWAPI(app_name)
  end


  # Setup the environment to call this provider
  def initConfigureCanvasESBProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:canvas_esb_application_name]
    logger.error "@@@@@@@@@@@@@@@@@@@@ need canvas_esb_application_name!" if application_name.nil?
    # This is hash with string replacement values.
    if !config_hash[application_name].nil? && !config_hash[application_name]['string-replace'].nil? then
      stringReplace = config_hash[application_name]['string-replace']
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: stringReplace [#{stringReplace.inspect}]"
    else
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: No string-replace specified for canvas esb application: [#{application_name}].  Supplying empty one."
      stringReplace = Hash.new()
    end

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider CanvasESB: security_file: [#{security_file}] application_name: [#{application_name}]"

    @canvasHash = Hash.new if @canvasHash.nil?

    @canvasHash[:useToDoLMSProvider] = true
    @canvasHash[:ToDoLMS] = Proc.new { |uniqname| canvasESBToDoLMS(uniqname, security_file, application_name) }
    @canvasHash[:formatResponse] = Proc.new { |body| CanvasAPIResponse.new(body, stringReplace) }

    initCanvasESB security_file, application_name
    @canvasHash
  end

  #  <canvas server>/api/v1/users/self/upcoming_events
  # actually call out to canvas and return the value.  Caller will reformat if necessary.
  def canvasESBToDoLMS(uniqname, security_file, esb_application)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ############### call canvas ESB todolms esb_application: #{esb_application}"
    logger.debug "##{self.class.to_s}:#{__method__}:#{__LINE__}: canvas ESB: @canvasESB_w: [#{@canvasESB_w}]"

    r = @canvasESB_w.get_request "/users/self/upcoming_events?as_user_id=sis_login_id:#{uniqname}"

    canvas_body = r.result
    canvas_body_ruby = JSON.parse canvas_body

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got todos from canvas esb", canvas_body_ruby)
  end

end
