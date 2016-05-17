module DataProviderCanvasESB

  require_relative 'WAPI_result_wrapper'
  require 'json'
  require 'rest-client'
  require 'yaml'

  # Implement calls for canvas data via ESB
  # e.g. /users/self/upcoming_events?as_user_id=sis_login_id:studenta

  # initialize variables local to this access method
  def initialize
    super()
    @canvasESB_w = ""
    @canvasESB_yml = ""
    @canvasESB_response = ""
    @canvasCalendarEvents = nil
  end

  ## Make a WAPI connection object.
  def setupCanvasWAPI(app_name)

    logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: setupCanvasAPI: canvasESB: use ESB application: #{app_name}"
    application = @canvasESB_yml[app_name]
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

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: init_ESB: use security file_name: #{file_name}"
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

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvas_calendar_events setup: #{CourseList.limit_msg(@canvas_calendar_events.inspect)}"
    logger.error "#{self.class.to_s}:#{__method__}:#{__LINE__}: need missing canvas_esb_application_name!" if application_name.nil?

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
    @canvasHash[:ToDoLMS] = Proc.new { |uniqname, canvas_courses| canvasESBToDoLMSClassByClass(uniqname, canvas_courses, security_file, application_name) }
    @canvasHash[:formatResponse] = Proc.new { |body| CanvasAPIResponse.new(body, stringReplace) }

    initCanvasESB security_file, application_name
    @canvasHash
  end


  def canvasAPICalendarEventsURL(uniqname, canvas_courses)

    ## calculate a multi day range around now for the assignment search (last week, today, next week).
    ## Can override defaults (above) in the studentdashboard.yml file.
    ## API call would support specifying attributes to ignore if we deem that necessary at some point.
    ## https://canvas.instructure.com/doc/api/calendar_events.html

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @canvas_calendar_events: #{CourseList.limit_msg(@canvas_calendar_events.inspect)}"

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
    string_request_url.gsub!(/%3A/, ':')
    full_request_url = string_request_url

    ### add repeating query parameters.  This is specific to course list
    full_request_url << CourseList.course_list_string(canvas_courses)

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: full_request_url: #{full_request_url}"
    full_request_url
  end

  # get calendar events for all the classes one by one.
  def canvasESBToDoLMSClassByClass(uniqname, canvas_courses, security_file, esb_application)
    canvas_courses ||= []
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: uniqname: [#{uniqname}] mpathways canvas_courses count: #{canvas_courses.length} canvas_courses: #{CourseList.limit_msg(canvas_courses.inspect)}"

    # Accumulate the data for each course.  Requests are done individually so that errors with one course
    # doesn't prevent getting data from the other courses.

    all_courses = canvas_courses.inject([]) do |all_classes, course|
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvas course array check course: [#{CourseList.limit_msg(course.inspect)}]"
      all_classes.concat(canvasCalendarEventsSingleCourse(course, uniqname))
      # block must return the accumulator used by inject.
      all_classes
    end
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: calendar_events_array count: #{all_courses.length} all_courses: #{CourseList.limit_msg(all_courses.inspect)}"

    WAPIResultWrapper.new(WAPIStatus::SUCCESS, "got calendar_events from canvas esb", all_courses)
  end

  # get calendar events for one class and handle unauthorized error condition explicitly.
  def canvasCalendarEventsSingleCourse(canvas_course, uniqname)
    calendar_events_url = canvasAPICalendarEventsURL(uniqname, [canvas_course])

    r = @canvasESB_w.get_request calendar_events_url
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: canvas_course: >#{canvas_course} result:#{CourseList.limit_msg(r.inspect)}"
    canvas_body = r.result

    if canvas_body.class == RestClient::Unauthorized
      # This is not an error since access may have been revoked on a class by class basis.
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: unauthorized access uniqname: #{uniqname} course: #{canvas_course}"
      return []
    end

    canvas_body_as_ruby = JSON.parse canvas_body
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: single course calendar events for canvas_course >>#{canvas_course}<< #{CourseList.limit_msg(canvas_body_as_ruby.inspect)}"
    canvas_body_as_ruby
  end

end
