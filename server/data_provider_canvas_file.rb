module DataProviderCanvasFile

  require_relative 'WAPI_result_wrapper'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for canvas data from file

  # initialize variables local to this access method
  def initialize
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ####### call super from initialize (CanvasFile)"
    super()
  end


  # Setup the environment to call this provider
  def initConfigureCanvasFileProvider(config_hash)
    #security_file = config_hash[:security_file]
    #application_name = config_hash[:canvas_esb_application_name]
    dpf_dir = config_hash[:data_provider_file_directory]

    # # This is hash with string replacement values.
    # if !config_hash[application_name].nil? && !config_hash[application_name]['string-replace'].nil? then
    #   stringReplace = config_hash[application_name]['string-replace']
    #   logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: stringReplace [#{stringReplace.inspect}]"
    # else
    #   logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: No string-replace specified for canvas file application: [#{application_name}].  Supplying empty one."
    #   stringReplace = Hash.new()
    # end

    stringReplace = Hash.new()

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider CanvasFile: dpf_dir: [#{dpf_dir}]"

    @canvasHash = Hash.new if @canvasHash.nil?

    @canvasHash[:useToDoLMSProvider] = true
    @canvasHash[:ToDoLMS] = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/todolms/canvas", uniqname) }
    @canvasHash[:formatResponse] = Proc.new { |body| CanvasAPIResponse.new(body, stringReplace) }

    #initCanvasESB security_file, application_name
    @canvasHash
  end

  # #  <canvas server>/api/v1/users/self/upcoming_events
  # # actually call out to canvas and return the value.  Caller will reformat if necessary.
  # def canvasESBToDoLMS(uniqname, security_file, esb_application)
  #   logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ############### call canvas ESB todolms esb_application: #{esb_application}"
  #   logger.debug "##{self.class.to_s}:#{__method__}:#{__LINE__}: canvas ESB: @canvasESB_w: [#{@canvasESB_w}]"
  #
  #   r = @canvasESB_w.get_request "/users/self/upcoming_events?as_user_id=sis_login_id:#{uniqname}"
  #
  #   canvas_body = r.result
  #   canvas_body_ruby = JSON.parse canvas_body
  #
  #   return WAPIResultWrapper.new(WAPI::SUCCESS, "got todos from canvas esb", canvas_body_ruby)
  # end

end
