###### ESB provider ################
# Use ESB to gather data for a request.

module DataProviderESB

  ## constants for understanding data from ESB.
  TERM_REG_KEY = 'getMyRegTermsResponse'
  TERM_KEY = 'Term'
  CLS_SCHEDULE_KEY = 'getMyClsScheduleResponse'
  REGISTERED_CLASSES_KEY = 'RegisteredClasses'

  # Persistent values.  These should not be class variables :-(
  @@w = nil
  @@yml = nil

  def setupWAPI(app_name)
    logger.info "setupWAPI: use ESB application: #{app_name}"
    application = @@yml[app_name]
    @@w = WAPI.new application
  end

  def initESB(security_file, app_name)

    requested_file = security_file

    default_security_file = './server/local/security.yml'

    if File.exist? requested_file
      file_name = requested_file
    else
      file_name = default_security_file
    end

    logger.info "init_ESB: use security file_name: #{file_name}"
    @@yml = YAML.load_file(file_name)

    setupWAPI(app_name)
  end

  def ensure_ESB(app_name, security_file)
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = initESB(security_file, app_name)
    end
  end

  # Run the request and return the resulting data.
  def callDataUrl(url)
    logger.debug("dataProviderESB  #{__LINE__}: CallDataUrl: #{__LINE__}: url: "+url)

    data = @@w.get_request(url)
    logger.debug("dataProviderESB  #{__LINE__}: CallDataUrl:  #{url}: data: "+data.inspect)
    result = data.result
    logger.debug("dataProviderESB  #{__LINE__}: CallDataUrl: result: "+result.inspect)
    result
  end

  # Run over a JSON compatible Ruby data structure and change any list containing just a single nil to be an empty list.
  # The object is changed in place.
  def fixArrayWithNilInPlace! (obj)
    case
      when obj.is_a?(Hash)
        obj.each { |key, value| fixArrayWithNilInPlace! value }
      when obj.is_a?(Array)
        # empty the array if it only contains a nil
        obj.pop if (obj.length == 1 && obj[0].is_a?(NilClass))
        # process any other entries in the array.
        obj.each { |value| fixArrayWithNilInPlace! value }
    end
    obj
  end

  # Accept string from ESB and extract out required information.  If the string is not valid JSON
  # that's an error.  'query_key' is the name of the mpathways script used to get the data. The 'detail_key'
  # is the part of the returned information we want to get.
  def parseESBData(result, query_key, detail_key)
    begin
      logger.debug("dataProviderESB parseESBData: #{__LINE__}:  input: #{result}: #{query_key}:#{detail_key}")
      # If it doesn't parse then it is a problem addressed in the rescue.
      parsed = JSON.parse(result)
      logger.debug("dataProviderESB parseESBData: #{__LINE__}:  parsed:"+parsed.inspect)
      query_key_value = parsed[query_key]

      ## Fix up unexpected values from ESB where there is no detail level data at all.  This can happen,
      ## for example, a user has no term data at all.
      ## Make these conditions separate so it will be easy to take out when ESB returns expected values.
      return WAPIResultWrapper.new(WAPI::SUCCESS, "replace nil value with empty array", []) if query_key_value.nil?
      return WAPIResultWrapper.new(WAPI::SUCCESS, "replace empty string with empty array", []) if query_key_value.length == 0

      # fix up any empty lists that only contain a nil.
      fixArrayWithNilInPlace! parsed

      parsed_value = parsed[query_key][detail_key]

      # if there is a detail_key but no data that's an error.
      raise "ESBInvalidData: input: #{result}" if parsed_value.nil?
      # we have data.
      return WAPIResultWrapper.new(WAPI::SUCCESS, "found value #{query_key}:#{detail_key} from ESB", parsed_value)
    rescue => excpt
      return WAPIResultWrapper.new(WAPI::UNKNOWN_ERROR, "bad data for key: #{query_key}:#{detail_key}: ",
                                   excpt.message+ " "+Logging.trimBackTraceRVM(excpt.backtrace).join("/n"))
    end
    # won't get here.
  end

  def dataProviderESBCourse(uniqname, termid, security_file, app_name, default_term)
    logger.info "data provider is DataProviderESB."
    ## if necessary initialize the ESB connection.
    ensure_ESB(app_name, security_file)

    if termid.nil?
      logger.debug "dPESBC: #{__LINE__}: defaulting term to #{default_term}"
      termid = default_term
    end

    url = "/Students/#{uniqname}/Terms/#{termid}/Schedule"
    result = callDataUrl(url)
    parseESBData(result, CLS_SCHEDULE_KEY, REGISTERED_CLASSES_KEY)
  end


  def dataProviderESBTerms(uniqname, security_file, app_name)
    logger.info "data provider is DataProviderESB."
    ## if necessary initialize the ESB connection.
    ensure_ESB(app_name, security_file)

    url = "/Students/#{uniqname}/Terms"
    result = callDataUrl(url)
    parseESBData(result, TERM_REG_KEY, TERM_KEY)
  end

  # get courses for a predefined user / term to allow non-authenticated performance check.
  def dataProviderESBCheck(security_file, app_name)

    ensure_ESB(app_name, security_file)

    # get the pre-defined check values
    check_uniqname = @@yml[app_name]['check_uniqname']
    check_termid = @@yml[app_name]['check_termid']

    raise "Bad check values for application: #{app_name} uniqname: [#{check_uniqname}] termid: [#{check_termid}]" unless (check_uniqname && check_termid)

    dataProviderESBCourse(check_uniqname, check_termid, security_file, app_name, nil)
  end

end
