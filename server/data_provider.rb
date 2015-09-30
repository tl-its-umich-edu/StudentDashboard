require_relative './data_provider_file'
require_relative './data_provider_esb'
require_relative '../server/data_provider_ctools_direct'
require_relative './ctools_direct_response'

module DataProvider

  # Map from generic calls for data to call(s) to specific providers.
  # TODO: Currently allows chosing between disk and esb providers for course data and
  # only supports httd direct access for ctools data.

  include DataProviderFile
  include DataProviderESB
  include DataProviderCToolsDirect

  attr_accessor :fileToDoLMS, :fileTerms, :fileCourses, :useFileProvider

  SERVICE_UNAVAILABLE = "503"

  # The init methods initialize specific provider implementations and hide details so that calls for data can be in
  # can be implementation agnostic.

  ## TODO: better to redo to have an init step per provider rather than to check this with every call.

  ## Initialize all the providers as configured.
  def dataProviderInit
    # only init if required.  At the moment if anything is configured they are all configured.
    return unless @fileToDoLMS.nil?
    logger.debug "#{__method__}: #{__LINE__}: init"
    config_hash = settings.latte_config

    !config_hash[:data_provider_file_directory].nil? ? configureFileProvider(config_hash) : configureEsbProvider(config_hash)
    configureCToolsHTTPProvider(config_hash)

  end

  ## Configuration binds implementation specific information to hide details and allow interchangable calling of
  ## any implementation regardless of configuration details.

  def configureFileProvider(config_hash)
    dpf_dir = config_hash[:data_provider_file_directory]
    logger.debug "configure provider file: directory: #{dpf_dir}"

    @useFileProvider = true
    @fileTerms = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/terms", uniqname) }
    @fileCourses = Proc.new { |uniqname, termid| dataProviderFileCourse(uniqname, termid, "#{dpf_dir}/courses") }
    @fileCheck = Proc.new { | | dataProviderFileCheck(config_hash[:data_provider_file_uniqname], "#{dpf_dir}/terms") }
  end

  def configureEsbProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:application_name]
    logger.debug "configure provider esb: security_file: #{security_file} application_name: #{application_name}"

    @useEsbProvider = true
    @esbTerms = Proc.new { |uniqname| dataProviderESBTerms(uniqname, security_file, application_name) }
    @esbCourses = Proc.new { |uniqname, termid| dataProviderESBCourse(uniqname, termid, security_file, application_name, config_hash[:default_term]) }
    @esbCheck = Proc.new { | | dataProviderESBCheck(security_file, application_name) }
  end

  def configureCToolsHTTPProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:ctools_http_application_name]
    logger.debug "#{__method__}: #{__LINE__}: configure provider CToolsHTTP: security_file: #{security_file} application_name: #{application_name}"

    @useCtoolsHTTPToDoLMSProvider = true
    @ctoolsHTTPDirectToDoLMS = Proc.new { |uniqname| ctoolsHTTPDirectToDoLMS(uniqname, security_file, application_name) }
  end

  ######################################

  ## These map to specific implementation calls.  Should probably
  ## pull them off a list of providers and return a list of results.

  def dataProviderCheck()

    logger.debug "DataProviderCheck"

    dataProviderInit

    check = @fileCheck.() if @useFileProvider
    check = @esbCheck.() if @useEsbProvider

    logIfUnavailable(check, "verify the check url configuration")

    check
  end

  def dataProviderToDoLMS(uniqname)

    logger.debug "#{__method__}: #{__LINE__}: DataProviderToDoLMS uniqname: #{uniqname}"

    dataProviderInit

    # TODO: add file based provider
    # TODO: add ESB based provider
    # TODO: add canvas information

    unless @useCtoolsHTTPToDoLMSProvider.nil?
      logger.error "#{__method__}: #{__LINE__}: deal with status in WAPI wrapper"
      raw_todos = @ctoolsHTTPDirectToDoLMS.(uniqname)
      # TODO: check if the wrapper status is ok
      # now strip off the wrapper
      result = raw_todos.result
      # reformat the result for the Dash UI format.
      todos = CToolsDirectResponse.new(result).toDoLms
      # rewrap it.
      todos = WAPIResultWrapper.new(WAPI::SUCCESS, "re-wrap ctools direct result",todos)
    end

    logger.debug "#{__method__}: #{__LINE__}: todos: #{todos}"
    logIfUnavailable(todos, "todolms: user: #{uniqname}")

    todos
  end

  def dataProviderTerms(uniqname)

    logger.debug "#{__method__}: DataProviderTerms uniqname: #{uniqname}"

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
    logger.warn("#{__method__}: #{__LINE__}: The provider response throttled or unavailable for: #{msg}") if SERVICE_UNAVAILABLE.casecmp(response.meta_status.to_s).zero?
  end

end
