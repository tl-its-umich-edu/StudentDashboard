module DataProviderESB

  @@w = nil
  @@yml = nil

  def setup_WAPI(app_name)
    logger.info "use ESB application: #{app_name}"
    application = @@yml[app_name]
    @@w = WAPI.new application
  end

  def init_ESB(security_file,app_name)

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

  def DataProviderESBCourse(uniqname, termid, security_file,app_name,default_term)
    logger.info "data provider is DataProviderESBCourse.\n"
    ## if necessary initialize the ESB connection.
    if @@w.nil?
      logger.debug "@@w is nil"
      @@w = init_ESB(security_file,app_name)
    end

    if termid.nil? || termid.length == 0
      logger.debug "defaulting term to #{default_term}"
      termid = default_term
    end

    url = "/Students/#{uniqname}/Terms/#{termid}/Schedule"

    logger.debug("ESB: url: "+url)
    logger.debug("@@w: "+@@w.to_s)

    classes = @@w.get_request(url)
    r = JSON.parse(classes)['getMyClsScheduleResponse']['RegisteredClasses']
    r2 = JSON.generate r

    return r2
  end
end
