###### ESB provider ################
# Use ESB to gather data for a request.
module DataProviderESB

  @@w = nil
  @@yml = nil


  def setup_WAPI(app_name)
    logger.info "use ESB application: #{app_name}"
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
    logger.debug "security file_name: #{file_name}"
    @@yml = YAML.load_file(file_name)

    setup_WAPI(app_name)
  end

  def DataProviderESBCourse(uniqname, termid, security_file, app_name, default_term)
    logger.info "data provider is DataProviderESBCourse."
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = init_ESB(security_file, app_name)
    end

    if termid.nil? || termid.length == 0
      logger.debug "defaulting term to #{default_term}"
      termid = default_term
    end

    url = "/Students/#{uniqname}/Terms/#{termid}/Schedule"

    logger.debug("ESB: url: "+url)

    classes = @@w.get_request(url)
    logger.debug("dataProviderESBCourse: classes: "+classes.inspect)
    #puts "#{__LINE__}: dataProviderESBCourse: classes: "+classes.inspect
    result = classes.result
    logger.debug("dataProviderESBCourse: result: "+result.inspect)

    r = JSON.parse(result)

    if r.has_key?('getMyClsScheduleResponse')
      r = r['getMyClsScheduleResponse']['RegisteredClasses']
      logger.debug("dataProviderESBCourse: with classes r: "+r.inspect)
      # return newly wrapped result after extracting the course data
      classes = WAPIResultWrapper.new(200, "found courses from ESB", r)
    end

    return classes
  end

  def DataProviderESBTerms(uniqname, termid, security_file, app_name, default_term)
    logger.info "data provider is DataProviderESBCourse."
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = init_ESB(security_file, app_name)
    end

    if termid.nil? || termid.length == 0
      logger.debug "defaulting term to #{default_term}"
      termid = default_term
    end

    url = "/Students/#{uniqname}/Terms/#{termid}"

    logger.debug("ESB: url: "+url)

    terms = @@w.get_request(url)
    logger.debug("#{__LINE__}: dataProviderESBTerms: terms: "+terms.inspect)
    puts "#{__LINE__}: dataProviderESBTerms: terms: "+terms.inspect
    result = terms.result
    puts "#{__LINE__}: dataProviderESBTerms: terms: "+terms.inspect

    r = JSON.parse(result)

    terms = WAPIResultWrapper.new(200, "found terms from ESB", r)

    return terms
  end

end
