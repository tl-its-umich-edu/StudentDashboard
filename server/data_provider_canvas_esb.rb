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
    @canvasCalendarEvents = nil
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

    if @canvas_calendar_events.nil?
      @canvas_calendar_events = config_hash[:canvas_calendar_events]
    end

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvas_calendar_events setup: #{@canvas_calendar_events.inspect}"


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
    @canvasHash[:ToDoLMS] = Proc.new { |uniqname, canvas_courses| canvasESBToDoLMS(uniqname, canvas_courses, security_file, application_name) }
    @canvasHash[:formatResponse] = Proc.new { |body| CanvasAPIResponse.new(body, stringReplace) }

    initCanvasESB security_file, application_name
    @canvasHash
  end


  def canvasAPICalendarEventsURL(uniqname, canvas_courses)

    ## calculate a multi day range around now for the assignment search (last week, today, next week).
    ## Can override defaults (above) in the studentdashboard.yml file.
    ## API call would support specifying attributes to ignore if we deem that necessary at some point.
    ## https://canvas.instructure.com/doc/api/calendar_events.html

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @canvas_calendar_events: #{@canvas_calendar_events.inspect}"

    # setup query parameters
    now = DateTime.now
    start_date = now.prev_day(@canvas_calendar_events['previous_days'])
    end_date = now.next_day(@canvas_calendar_events['next_days'])

    max_results_per_page = @canvas_calendar_events['max_results_per_page']

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: start: #{start_date} now: #{now} end: #{end_date}"

    request_url = "/users/self/calendar_events"

    request_parameters = {:params => {:as_user_id => "sis_login_id:#{uniqname}",
                                      :type => 'assignment',
                                      :start_date => start_date,
                                      :end_date => end_date,
                                      :per_page => max_results_per_page
    }}

    # Generate url with query parameters.
    string_request_url = RestClient::Request.new(:method => :get, :url => request_url, :headers => request_parameters).url
    #### test to see if need to unescape :
    string_request_url.gsub!(/%3A/, ':')
    #puts string_request_url.inspect
    full_request_url = string_request_url

    ### add repeating query parameters.  This is specific to course list
    full_request_url << CourseList.course_list_string(canvas_courses)

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: full_request_url: #{full_request_url}"
    full_request_url
  end

  #  <canvas server>/api/v1/users/self/calendar_events
  def canvasESBToDoLMS(uniqname, canvas_courses, security_file, esb_application)
    canvas_courses ||= []
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ############### call canvas ESB todolms esb_application: #{esb_application}"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvas ESB: @canvasESB_w: [#{@canvasESB_w}]"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvas_courses count: #{canvas_courses.length} canvas_courses: #{canvas_courses}"

    calendar_events_url = canvasAPICalendarEventsURL(uniqname, canvas_courses)

    r = @canvasESB_w.get_request calendar_events_url

    canvas_body = r.result
    canvas_body_ruby = JSON.parse canvas_body

    return WAPIResultWrapper.new(WAPI::SUCCESS, "got calendar_events from canvas esb", canvas_body_ruby)
  end


  #  <canvas server>/api/v1/users/self/upcoming_events
  # actually call out to canvas and return the value.  Caller will reformat if necessary.
  # def canvasESBToDoLMS_upcoming_events(uniqname, security_file, esb_application)
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

  # fake list of "canvas_courses"=>["43412", "44525", "44526", "44631", "44630", "44528", "44530"]}

end
