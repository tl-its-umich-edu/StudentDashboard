require_relative './data_provider_file'
require_relative './data_provider_esb'
require_relative './data_provider_ctools_direct'
require_relative './data_provider_ctools_file'
require_relative './data_provider_canvas_direct'
require_relative './data_provider_canvas_esb'
require_relative './data_provider_canvas_file'
require_relative './ctools_direct_response'
require_relative './mneme_api_response'
require_relative './canvas_api_response'

module DataProvider

  # Map from generic calls for data to call(s) to specific providers.
  # OVERVIEW: There are 3 sources of data, MPathways, CTools and Canvas.
  # There are two different calls to CTools: dashboard and mneme data.
  # This code does the mapping between requests for types of data and
  # calls to specific providers and takes care of provisioning the providers.

  include DataProviderFile
  include DataProviderESB
  include DataProviderCToolsDirect
  include DataProviderCToolsFile
  include DataProviderCanvasDirect
  include DataProviderCanvasESB
  include DataProviderCanvasFile

  attr_accessor :fileToDoLMS, :fileTerms, :fileCourses, :useFileProvider

  SERVICE_UNAVAILABLE = "503"

  # initialize the module.  Similar to class initialization.
  def initialize
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: ####### call super from initialize (CanvasESB)"
    super()
    @ctools_hash = Hash.new()
  end

  ################## Requests for data about individuals.

  # These are Data urls reasonable for a user to call.  They correspond to elements visible to outside users.

  def dataProviderCheck()

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: DataProviderCheck"

    dataProviderInit

    check = @fileCheck.() if @useFileProvider
    check = @esbCheck.() if @useEsbProvider

    logIfUnavailable(check, "verify the check url configuration")

    check
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

  # Call the right source of specific todo data.
  def dataProviderToDoLMS(uniqname, lms)

    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: uniqname: #{uniqname} lms: [#{lms}] session: [#{CourseList.limit_msg(session.inspect)}]"

    dataProviderInit
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: @ctools_hash [#{@ctools_hash.inspect}]"
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: @canvas_hash [#{@canvas_hash.inspect}]"
    return dataProviderToDoCToolsLMS(uniqname, @ctools_hash) if lms == 'ctools'
    return dataProviderToDoCToolsPastLMS(uniqname, @ctools_hash) if lms == 'ctoolspast'
    return dataProviderToDoCanvasLMS(uniqname, session[:canvas_courses], @canvas_hash) if lms == 'canvas'
    return dataProviderToDoMnemeLMS(uniqname, @ctools_hash) if lms == 'mneme'
  end

  ################## recursive REST data requests for ToDo / Schedule information

  # There is different configuration for the different sources of TODO / Schedule information.
  # The requests for each specific method are handled here.

  # Get and format the the todo values
  def get_and_format_todos(method_hash, uniqname, provider_args)

    unless method_hash[provider_args[:provider_type]].nil?
      # call with extra argument if necessary
      raw_todos = provider_args[:canvas_course_list] ? method_hash[provider_args[:provider]].(uniqname, provider_args[:canvas_course_list]) : method_hash[provider_args[:provider]].(uniqname)
      result = raw_todos.result
      todos = method_hash[provider_args[:formatter]].(result).toDoLms
      todos = WAPIResultWrapper.new(WAPI::SUCCESS, provider_args[:wapi_msg], todos)
    end

    todos
  end

  # setup call and return as json, add debugging.
  def get_todos_as_json(method_hash, provider_args, uniqname)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: uniqname: [#{uniqname}]"
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: provider_args: [#{provider_args}]"
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: method_hash [#{CourseList.limit_msg(method_hash.inspect)}]"

    todos = get_and_format_todos(method_hash, uniqname, provider_args)

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: todos #{CourseList.limit_msg(todos.inspect)}"
    logIfUnavailable(todos, "todolms: user: #{uniqname}")

    todos.value_as_json
  end

  def dataProviderToDoCToolsLMS(uniqname, method_hash)

    provider_args = {
        :provider_type => :ToDoLMSProviderDash,
        :provider => :ToDoLMSDash,
        :formatter => :formatResponseCToolsDash,
        :wapi_msg => "re-wrap ctools Dash direct result"
    }

    get_todos_as_json(method_hash, provider_args, uniqname)
  end


  def dataProviderToDoCToolsPastLMS(uniqname, method_hash)

    provider_args = {
        :provider_type => :ToDoLMSProviderDashPast,
        :provider => :ToDoLMSDashPast,
        :formatter => :formatResponseCToolsDashPast,
        :wapi_msg => "re-wrap ctools past Dash direct result"
    }

    get_todos_as_json(method_hash, provider_args, uniqname)
  end

  def dataProviderToDoCanvasLMS(uniqname, canvas_courses, method_hash)

    provider_args = {
        :provider_type => :useToDoLMSProvider,
        :provider => :ToDoLMS,
        :formatter => :formatResponse,
        :wapi_msg => "re-wrap Canvas API result",
        :canvas_course_list => canvas_courses,
    }

    get_todos_as_json(method_hash, provider_args, uniqname)
  end


  def dataProviderToDoMnemeLMS(uniqname, method_hash)

    provider_args = {
        :provider_type => :ToDoLMSProviderMneme,
        :provider => :ToDoLMSMneme,
        :formatter => :formatResponseCToolsMneme,
        :wapi_msg => "re-wrap mneme result",
    }

    get_todos_as_json(method_hash, provider_args, uniqname)
  end

  ############## Initialize and configure

  # The init methods initialize specific provider implementations and hide details so that calls for data can be in
  # can be implementation agnostic.

  ## TODO: better to redo to have an init step per provider rather than to check this with every call.

  ## Initialize all the providers as configured.
  def dataProviderInit
    # only init if required.  At the moment if anything is configured they are all configured.
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: return as fileToDoLMS is not nil" unless @fileToDoLMS.nil?
    return unless @fileToDoLMS.nil?
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call dataProviderInit"
    config_hash = settings.latte_config

    # Configure providers for the different sources of data

    # Mpathways provider
    configureMPathwaysProvider(config_hash)
    configureCToolsProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configureCanvasProvider"
    configureCanvasProvider(config_hash)

  end

  def configureMPathwaysProvider(config_hash)
    logger.error "@@@@@@@@@@@@@ must specify one MPathways data provider" unless verifyExactlyOneProvider(config_hash, [:data_provider_file_directory, :mpathways_application_name])
    configureFileProvider(config_hash) unless config_hash[:data_provider_file_directory].nil?
    configureEsbProvider(config_hash) unless config_hash[:mpathways_application_name].nil?
  end

  ### Hide any decisions about which ctools connection method to use.
  def configureCToolsProvider(config_hash)
    logger.error "@@@@@@@@@@@@@ must specify one CTools data provider" unless verifyExactlyOneProvider(config_hash, [:data_provider_file_directory, :ctools_http_application_name])
    configureCToolsFileProvider(config_hash) unless (config_hash[:data_provider_file_directory].nil?)
    configureCToolsHTTPProvider(config_hash) unless (config_hash[:ctools_http_application_name].nil?)
  end

  ## These methods delegate configuration to the provider.
  def configureCToolsFileProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    # Assign or merge hash?
    @ctools_hash = initConfigureCToolsFileProvider(config_hash)
  end

  ## These methods delegate configuration to the provider.
  def configureCanvasFileProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    # Assign or merge hash?
    @canvas_hash = initConfigureCanvasFileProvider(config_hash)
  end

  ### Hide any decisions about which canvas provider to use.
  def configureCanvasProvider(config_hash)
    logger.error "@@@@@@@@@@@@@ must specify one canvas data provider" unless verifyExactlyOneProvider(config_hash, [:data_provider_file_directory, :canvas_esb_application_name, :canvas_http_application_name])
    configureCanvasFileProvider(config_hash) unless (config_hash[:data_provider_file_directory].nil?)
    configureCanvasESBProvider(config_hash) unless (config_hash[:canvas_esb_application_name].nil?)
    configureCanvasHTTPProvider(config_hash) unless (config_hash[:canvas_http_application_name].nil?)
  end

  ## Configuration binds implementation specific information to hide details and allow interchangable calling of
  ## any implementation regardless of configuration details.

  ## TODO: should apply to all data sources including ToDo
  def configureFileProvider(config_hash)
    dpf_dir = config_hash[:data_provider_file_directory]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider file: directory: [#{dpf_dir}]"

    @useFileProvider = true
    @fileTerms = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/terms", uniqname) }
    @fileCourses = Proc.new { |uniqname, termid| dataProviderFileCourse(uniqname, termid, "#{dpf_dir}/courses") }
    @fileCheck = Proc.new { | | dataProviderFileCheck(config_hash[:data_provider_file_uniqname], "#{dpf_dir}/terms") }
  end

  # Use the ESB to get MPathways information
  def configureEsbProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:mpathways_application_name]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider esb: security_file: [#{security_file}] application_name: [#{application_name}]"

    @useEsbProvider = true
    @esbTerms = Proc.new { |uniqname| dataProviderESBTerms(uniqname, security_file, application_name) }
    @esbCourses = Proc.new { |uniqname, termid| dataProviderESBCourse(uniqname, termid, security_file, application_name, config_hash[:default_term]) }
    @esbCheck = Proc.new { | | dataProviderESBCheck(security_file, application_name) }
  end

  ## These methods delegate configuration to the provider.
  def configureCToolsHTTPProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    # Assign or merge hash?
    @ctools_hash = initConfigureCToolsHTTPProvider(config_hash)
  end

  ## These methods delegate configuration to the provider.

  #### temp
  def initConfigureMnemeFileProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: called init"
    @ctools_hash = Hash.new if @ctools_hash.nil?
    logger.error "#{self.class.to_s}:#{__method__}:#{__LINE__}: ######## fix dpfd"
    dpf_dir = config_hash[:data_provider_file_directory]

    @ctools_hash[:ToDoLMSMProviderMneme] = true
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: dpf_dir: #{dpf_dir}"
    @ctools_hash[:ToDoLMSMneme] = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/todolms/mneme", uniqname) }
    @ctools_hash[:formatResponseCToolsMneme] = Proc.new { |body| MnemeAPIResponse.new(body) }
    @ctools_hash
  end

  def configureMnemeFileProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    @ctools_hash = Hash.new if @ctools_hash.nil?
    @ctools_hash.merge!(initConfigureMnemeFileProvider(config_hash))
  end

  def configureCanvasHTTPProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure"
    # is this a bug?  Might it exist but be empty?
    return @canvas_hash unless @canvas_hash.nil?
    @canvas_hash = initConfigureCanvasHTTPProvider(config_hash)
  end

  def configureCanvasESBProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: call configure @canvas_hash: #{@canvas_hash}"
    # is this a bug?  Might it exist but be empty?
    return @canvas_hash unless @canvas_hash.nil?
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: setup canvasHash"
    @canvas_hash = initConfigureCanvasESBProvider(config_hash)
    logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: setup canvasHash"
  end

  ######################################  UTILITY CLASSES

  def logIfUnavailable(response, msg)
    logger.warn("#{self.class.to_s}:#{__method__}: #{__LINE__}: The provider response throttled or unavailable for: #{msg}") if SERVICE_UNAVAILABLE.casecmp(response.meta_status.to_s).zero?
  end


  # Merge results of separate feeds of ctools data.
  def mergeCtoolsDashMneme(dash_result, mneme_result)

    #modify so that can an array of entries and merge them all.

    # Reconstitute the WAPI wrapper for the feed results.  The data came from recursive calls to this
    # servlet so they are in string format here.

    dash_w = WAPIResultWrapper.new("status", "msg", "result")
    dash_w.setValue(dash_result)

    mneme_w = WAPIResultWrapper.new("status", "msg", "result")
    mneme_w.setValue(mneme_result)

    combined_w = WAPIResultWrapper.new("200",
                                       "combined the ctools dash and mneme feeds",
                                       dash_w.result+mneme_w.result)
    combined_w.value
  end

  ## make sure there is just one provider specified for this data stream.
  def verifyExactlyOneProvider(config_hash, possible_providers)
    if logger.debug then
      possible_providers.each { |provider_symbol| logger.debug "#{self.class.to_s}:#{__method__}: #{__LINE__}: possible provider: [#{provider_symbol.to_s}] value: [#{config_hash[provider_symbol].to_s}]" }
    end
    return possible_providers.one? { |provider_symbol| !config_hash[provider_symbol].nil? }
  end

end
