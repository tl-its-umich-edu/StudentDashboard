require_relative './data_provider_file'
require_relative './data_provider_esb'
require_relative './data_provider_ctools_direct'
require_relative './data_provider_canvas_direct'
require_relative './data_provider_canvas_esb'
require_relative './ctools_direct_response'
require_relative './mneme_api_response'
require_relative './canvas_api_response'

module DataProvider

  # Map from generic calls for data to call(s) to specific providers.

  include DataProviderFile
  include DataProviderESB
  include DataProviderCToolsDirect
  include DataProviderCanvasDirect
  include DataProviderCanvasESB

  attr_accessor :fileToDoLMS, :fileTerms, :fileCourses, :useFileProvider

  SERVICE_UNAVAILABLE = "503"

  def initialize
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ####### call super from initialize (CanvasESB)"
    super()
  end

  # The init methods initialize specific provider implementations and hide details so that calls for data can be in
  # can be implementation agnostic.

  ## TODO: better to redo to have an init step per provider rather than to check this with every call.

  ## Initialize all the providers as configured.
  def dataProviderInit
    # only init if required.  At the moment if anything is configured they are all configured.
    return unless @fileToDoLMS.nil?
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: init"
    config_hash = settings.latte_config
   # logger.debug "#{__method__}: #{__LINE__}: config_hash: #{config_hash.to_json}"
    !config_hash[:data_provider_file_directory].nil? ? configureFileProvider(config_hash) : configureEsbProvider(config_hash)

    configureCToolsProvider(config_hash)
    configureCanvasProvider(config_hash)

  end

  ### Hide any decisions about which ctools provider to use.  Mneme data is from CTools also, so
  ### no need to have a different configure method.
  def configureCToolsProvider(config_hash)
    configureCToolsHTTPProvider(config_hash) unless(config_hash[:ctools_http_application_name].nil?)
    logger.error "#{self.class.to_s}:#{__method__}:#{__LINE__}: using hardwired Mneme file provider"
    configureMnemeFileProvider(config_hash);
  end

  ### Hide any decisions about which canvas provider to use.
  def configureCanvasProvider(config_hash)
    configureCanvasESBProvider(config_hash) unless(config_hash[:canvas_esb_application_name].nil?)
    configureCanvasHTTPProvider(config_hash) unless(config_hash[:canvas_http_application_name].nil?)
  end

  ## Configuration binds implementation specific information to hide details and allow interchangable calling of
  ## any implementation regardless of configuration details.

  def configureFileProvider(config_hash)
    dpf_dir = config_hash[:data_provider_file_directory]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider file: directory: [#{dpf_dir}]"

    @useFileProvider = true
    @fileTerms = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/terms", uniqname) }
    @fileCourses = Proc.new { |uniqname, termid| dataProviderFileCourse(uniqname, termid, "#{dpf_dir}/courses") }
    @fileCheck = Proc.new { | | dataProviderFileCheck(config_hash[:data_provider_file_uniqname], "#{dpf_dir}/terms") }
  end

  def configureEsbProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:application_name]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider esb: security_file: [#{security_file}] application_name: [#{application_name}]"

    @useEsbProvider = true
    @esbTerms = Proc.new { |uniqname| dataProviderESBTerms(uniqname, security_file, application_name) }
    @esbCourses = Proc.new { |uniqname, termid| dataProviderESBCourse(uniqname, termid, security_file, application_name, config_hash[:default_term]) }
    @esbCheck = Proc.new { | | dataProviderESBCheck(security_file, application_name) }
  end

  ## These methods delegate configuration to the provider.
  def configureCToolsHTTPProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    return @ctoolsHash unless @ctoolsHash.nil?
    @ctoolsHash = initConfigureCToolsHTTPProvider(config_hash)
  end

  ## These methods delegate configuration to the provider.

  #### temp
  def initConfigureMnemeFileProvider(config_hash)
    @mnemeHash = Hash.new if @mnemeHash.nil?
    dpf_dir = config_hash[:data_provider_file_directory_mneme]

    @mnemeHash[:ToDoLMSProvider] = true
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: dpf_dir: #{dpf_dir}"
    @mnemeHash[:ToDoLMS] = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/todolms/mneme", uniqname) }
    @mnemeHash
  end

  def configureMnemeFileProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    return @mnemeHash unless @mnemeHash.nil?
    @mnemeHash = initConfigureMnemeFileProvider(config_hash)
  end

  # def configureMnemeHTTPProvider(config_hash)
  #   logger.debug "#{__method__}: #{__LINE__}: call configure"
  #   return @mnemeHash unless @mnemeHash.nil?
  #   @mnemeHash = initConfigureMnemeHTTPProvider(config_hash)
  # end

  def configureCanvasHTTPProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    return @canvasHash unless @canvasHash.nil?
    @canvasHash = initConfigureCanvasHTTPProvider(config_hash)
  end

  def configureCanvasESBProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    return @canvasHash unless @canvasHash.nil?
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: setup canvasHash"
    @canvasHash = initConfigureCanvasESBProvider(config_hash)
  end

  ######################################

  ## These map to specific implementation calls.  Should probably
  ## pull them off a list of providers and return a list of results.

  def dataProviderCheck()

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: DataProviderCheck"

    dataProviderInit

    check = @fileCheck.() if @useFileProvider
    check = @esbCheck.() if @useEsbProvider

    logIfUnavailable(check, "verify the check url configuration")

    check
  end

  def dataProviderToDoCToolsLMS(uniqname)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: DataProviderToDoCToolsLMS uniqname: #{uniqname}"

    dataProviderInit

    unless @ctoolsHash[:ToDoLMSProvider].nil?
      logger.error "#{self.class.to_s}:#{__method__}: #{__LINE__}: deal with status in WAPI wrapper"

      raw_todos = @ctoolsHash[:ToDoLMS].(uniqname)
      # TODO: check if the wrapper status is ok
      # now strip off the wrapper
      result = raw_todos.result
      # reformat the result for the Dash UI format.
      todos = CToolsDirectResponse.new(result).toDoLms
      # Put a new WAPI wrapper around it.
      todos = WAPIResultWrapper.new(WAPI::SUCCESS, "re-wrap ctools direct result",todos)
    end

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ctools: todos: [#{todos}]"
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ctools: todos.value_as_json: #{todos.value_as_json}"
    logIfUnavailable(todos, "todolms: ctools: user: #{uniqname}")

    todos.value_as_json
  end


  def dataProviderToDoCanvasLMS(uniqname)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}:  uniqname: #{uniqname}"

    dataProviderInit

    logger.debug "@canvasHash: #{@canvasHash.inspect}"

    unless @canvasHash[:useToDoLMSProvider].nil?
      logger.error "#{self.class.to_s}:#{__method__}: #{__LINE__}: deal with status in WAPI wrapper"

      raw_todos = @canvasHash[:ToDoLMS].(uniqname)
      # TODO: check if the wrapper status is ok
      # now strip off the wrapper
      result = raw_todos.result
      # TODO: do the reformatting
      # reformat the result for the Dash UI format.

      todos = @canvasHash[:formatResponse].(result.to_json).toDoLms
      # rewrap the formatted result.
      todos = WAPIResultWrapper.new(WAPI::SUCCESS, "re-wrap Canvas API result",todos)
    end

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: canvas: todos.value_as_json: #{todos.value_as_json}"
    logIfUnavailable(todos, "todolms: canvas: user: #{uniqname}")

    todos.value_as_json
  end

  def dataProviderToDoMnemeLMS(uniqname)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: DataProviderToDoMnemeLMS uniqname: #{uniqname}"

    dataProviderInit

    unless @mnemeHash[:ToDoLMSProvider].nil?
      logger.error "#{self.class.to_s}:#{__method__}: #{__LINE__}: deal with status in WAPI wrapper"

      raw_todos = @mnemeHash[:ToDoLMS].(uniqname)
      # TODO: check if the wrapper status is ok
      # now strip off the wrapper
      result = raw_todos.result
      # reformat the result for the Dash UI format.
      todos = MnemeAPIResponse.new(result.to_json).toDoLms
      #todos = result
      # Put a new WAPI wrapper around it.
      todos = WAPIResultWrapper.new(WAPI::SUCCESS, "re-wrap mneme result",todos)
    end

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: mneme: todos: [#{todos}]"
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: mneme: todos.value_as_json: #{todos.value_as_json}"
    logIfUnavailable(todos, "todolms: mneme: user: #{uniqname}")

    todos.value_as_json
  end

  #
  ## return the data from the right source.
  def dataProviderToDoLMS(uniqname,lms)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: DataProviderToDoLMS uniqname: #{uniqname} lms: [#{lms}]"

    return dataProviderToDoCToolsLMS(uniqname) if lms == 'ctools'
    return dataProviderToDoCanvasLMS(uniqname) if lms == 'canvas'
    return dataProviderToDoMnemeLMS(uniqname)  if lms == 'mneme'
  end


  def dataProviderTerms(uniqname)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: DataProviderTerms uniqname: #{uniqname}"

    dataProviderInit

    terms = @fileTerms.(uniqname) if @useFileProvider
    terms = @esbTerms.(uniqname) if @useEsbProvider

    logIfUnavailable(terms, "terms: user: #{uniqname}")

    terms
  end

  def dataProviderCourse(uniqname, termid)

    dataProviderInit

    courses = @fileCourses.(uniqname, termid) if @useFileProvider
    courses = @esbCourses.(uniqname, termid) if @useEsbProvider

    logIfUnavailable(courses, "courses: user: #{uniqname} term:#{termid}")

    courses
  end

  def logIfUnavailable(response, msg)
    logger.warn("#{self.class.to_s}:#{__method__}: #{__LINE__}: The provider response throttled or unavailable for: #{msg}") if SERVICE_UNAVAILABLE.casecmp(response.meta_status.to_s).zero?
  end

end
