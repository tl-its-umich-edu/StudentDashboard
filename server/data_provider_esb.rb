###### ESB provider ################
# Use ESB to gather data for a request.

module DataProviderESB

  @@w = nil
  @@yml = nil

  def setup_WAPI(app_name)
    logger.info "setup_WAPI: use ESB application: #{app_name}"
    application = @@yml[app_name]
    @@w = WAPI.new application
  end

  def init_ESB(security_file, app_name)

    logger.info "init_ESB"
    logger.info("security_file: "+security_file.to_s)

    requested_file = security_file

    default_security_file = './server/local/security.yml'

    if File.exist? requested_file
      file_name = requested_file
    else
      file_name = default_security_file
    end

    logger.debug "init_ESB: security file_name: #{file_name}"
    @@yml = YAML.load_file(file_name)

    setup_WAPI(app_name)
  end

  def dataProviderESBCourse(uniqname, termid, security_file, app_name, default_term)
    logger.info "data provider is DataProviderESB."
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = init_ESB(security_file, app_name)
    end

    if termid.nil? || termid.length == 0
      logger.debug "dPESBC: #{__LINE__}: defaulting term to #{default_term}"
      termid = default_term
    end

    url = "/Students/#{uniqname}/Terms/#{termid}/Schedule"

    logger.debug("dPESBC: #{__LINE__}: url: "+url)

    classes = @@w.get_request(url)
    logger.debug("dPESBC: classes: "+classes.inspect)
    result = classes.result
    logger.debug("dPESBC: result: "+result.inspect)

    begin
    r = JSON.parse(result)
    rescue => exp
      logger.warn("EXCEPTION: dataProviderESBCourse: course request exp: "+exp+" result: "+r.inspect)
      return WAPIResultWrapper.new(666, "EXCEPTION: course request returned: ", r)
    end

    if r.has_key?('getMyClsScheduleResponse')
      r = r['getMyClsScheduleResponse']['RegisteredClasses']
      logger.debug("dPESBC: with classes r: "+r.inspect)
      # return newly wrapped result after extracting the course data
      classes = WAPIResultWrapper.new(200, "found courses from ESB", r)
    end

    return classes
  end

  def dataProviderESBTerms(uniqname, security_file, app_name)
    logger.info "data provider is DataProviderESB."
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = init_ESB(security_file, app_name)
    end

    url = "/Students/#{uniqname}/Terms"

    logger.debug("DPESBT: url: "+url)

    terms = @@w.get_request(url)
    logger.debug("DPESBT: #{__LINE__}: dataProviderESBTerms: terms: "+terms.inspect)
    result = terms.result
    logger.debug("DPESBT: #{__LINE__}: dataProviderESBTerms: result: "+result.inspect)

    begin
      parsed = JSON.parse(result)
    rescue => exp
      logger.warn("EXCEPTION: dataProviderESBTerm: term request returned: exp: "+exp+" result: "+result.inspect)
      return WAPIResultWrapper.new(666, "EXCEPTION: term request parsing", result)
    end

    if parsed.has_key?('getMyRegTermsResponse')
      terms_value = parsed['getMyRegTermsResponse']['Term']
      terms = WAPIResultWrapper.new(200, "found terms from ESB", terms_value)
    end

    return terms
  end

end
