require_relative './data_provider_file'
require_relative './data_provider_esb'

module DataProvider

  # Map from generic calls for data to call(s) to specific providers.
  # TODO: Currently this only supports a single provider (file or esb).  This will change.
  # TODO: current last active provider wins, that must change when use both ctools and canvas providers.

  include DataProviderFile
  include DataProviderESB

  attr_accessor :fileToDoLMS, :fileTerms, :fileCourses, :useFileProvider

  SERVICE_UNAVAILABLE = "503"

  # The init methods initialize specific provider implementations and hide details so that calls for data can be in
  # can be implementation agnostic.

  ## TODO: better to redo to have an init step per provider rather than to check this with every call.
  def dataProviderInit
    # only init if required.  At the moment if anything is configured they are all configured.
    return unless @fileToDoLMS.nil?
    logger.debug "#{__method__}: #{__LINE__}: init"
    config_hash = settings.latte_config

    !config_hash[:data_provider_file_directory].nil? ? configureFileProvider(config_hash) : configureEsbProvider(config_hash)

  end

  def configureFileProvider(config_hash)
    dpf_dir = config_hash[:data_provider_file_directory]
    logger.debug "configure provider file: directory: #{dpf_dir}"

    @useFileProvider = true
    @fileToDoLMS = Proc.new { |uniqname| dataProviderFileToDoLMS(uniqname, "#{dpf_dir}/todolms") }
    @fileTerms = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/terms", uniqname) }
    @fileCourses = Proc.new { |uniqname, termid| dataProviderFileCourse(uniqname, termid, "#{dpf_dir}/courses") }
    @fileCheck = Proc.new { | | dataProviderFileCheck(config_hash[:data_provider_file_uniqname], "#{dpf_dir}/terms") }
  end

  def configureEsbProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:application_name]
    logger.debug "configure provider esb: security_file: #{security_file} application_name: #{application_name}"

    @useEsbProvider = true
    @esbToDoLMS = Proc.new { |uniqname| dataProviderESBToDoLMS(uniqname, security_file, application_name) }
    @esbTerms = Proc.new { |uniqname| dataProviderESBTerms(uniqname, security_file, application_name) }
    @esbCourses = Proc.new { |uniqname, termid| dataProviderESBCourse(uniqname, termid, security_file, application_name, config_hash[:default_term]) }
    @esbCheck = Proc.new { | | dataProviderESBCheck(security_file, application_name) }
  end

  ######################################

  def dataProviderCheck()

    logger.debug "DataProviderCheck"

    dataProviderInit

    check = @fileCheck.() if @useFileProvider
    check = @esbCheck.() if @useEsbProvider

    logIfUnavailable(check, "verify the check url configuration")

    check
  end

  def dataProviderToDoLMS(uniqname)

    logger.debug "DataProviderToDoLMS uniqname: #{uniqname}"

    dataProviderInit

    todos = @fileToDoLMS.(uniqname) if @useFileProvider
    todos = @esbToDoLMS.(uniqname) if @useEsbProvider

    logIfUnavailable(terms, "todolms: user: #{uniqname}")

    todos
  end

  def dataProviderTerms(uniqname)

    logger.debug "#{__method__}: DataProviderTerms uniqname: #{uniqname}"

    dataProviderInit

    #puts "@useFileProvider: #{@useFileProvider}"
    terms = @fileTerms.(uniqname) if @useFileProvider
    #puts "dPTerms A: "+terms.to_s
    #puts "@useEsbProvider: #{@useEsbProvider}"
    terms = @esbTerms.(uniqname) if @useEsbProvider
    #puts "dPTerms B: "+terms.to_s

    logIfUnavailable(terms, "terms: user: #{uniqname}")

    terms
  end

  ## Use the appropriate provider implementation.
  ## This should be implemented to set the desired function upon configuration rather than
  ## to look it up with each request.
  def dataProviderCourse(uniqname, termid)

    dataProviderInit

    courses = @fileCourses.(uniqname, termid) if @useFileProvider
    courses = @esbCourses.(uniqname, termid) if @useEsbProvider

    logIfUnavailable(courses, "courses: user: #{uniqname} term:#{termid}")

    courses
  end

  def logIfUnavailable(response, msg)
    logger.warn("the provider response throttled or unavailable for: #{msg}") if SERVICE_UNAVAILABLE.casecmp(response.meta_status.to_s).zero?
  end

end
