module DataProviderCToolsFile

  # stub the ToDoLMS feeds sourced from CTools to use local files.

  require_relative 'WAPI_result_wrapper'
  require 'json'
  require 'rest-client'
  require 'yaml'

  ### Setup to call CTools ToDoLMS data from files.
  def initConfigureCToolsFileProvider(config_hash)
    security_file = config_hash[:security_file]
    application_name = config_hash[:ctools_http_application_name]

    # This is hash with string replacement values.
    if !config_hash[application_name].nil? && !config_hash[application_name]['string-replace'].nil? then
      stringReplace = config_hash[application_name]['string-replace']
      logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: stringReplace [#{stringReplace.inspect}]"
    else
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: No string-replace specified for ctools file provider application: [#{application_name}].  Supplying empty one."
      stringReplace = Hash.new()
    end

    dpf_dir = config_hash[:data_provider_file_directory]
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: configure provider CToolsHTTP: security_file: #{security_file} application_name: #{application_name}"

    @ctoolsHash = Hash.new if @ctoolsHash.nil?

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{@ctoolsHash.inspect}]"
    return @ctoolsHash unless @ctoolsHash[:ToDoLMSProviderDash].nil?

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{@ctoolsHash.inspect}]"

    ## setup the dashboard query
    @ctoolsHash[:ToDoLMSProviderDash] = true
    @ctoolsHash[:ToDoLMSDash] = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/todolms/ctools", uniqname) }
    @ctoolsHash[:formatResponseCToolsDash] = Proc.new { |body| CToolsDirectResponse.new(body.to_json,stringReplace) }

    ## setup the mneme query
    @ctoolsHash[:ToDoLMSProviderMneme] = true
    @ctoolsHash[:ToDoLMSMneme] = Proc.new { |uniqname| dataProviderFileTerms("#{dpf_dir}/todolms/mneme", uniqname) }
    @ctoolsHash[:formatResponseCToolsMneme] = Proc.new { |body| MnemeAPIResponse.new(body.to_json,stringReplace) }

    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: @ctoolsHash: [#{@ctoolsHash.inspect}]"

    @ctoolsHash
  end

end
