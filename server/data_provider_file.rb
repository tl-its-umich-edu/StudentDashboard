module DataProviderFile

  require_relative 'WAPI_result_wrapper'

###### File provider ################
### Return the data for a request from a matching file.  The file will be in the
### directory specified.
### The name of the file must be <name>.json.  The <name> will be the user name.
### For testing this need not be a uniqname but can be any name that maps to a file.
### The url localhost:3000/courses/abba.json would map to a file named abba.json in the
### specified directory under the default test-files directory.

## Use these values for the Student Dashboard check call.  Use static values since the file provider has
## no configuration.  There must be a corresponding data file.  The "default" file should always
## be available.

  @@default_uniqname="default"
  @@default_term=2010

  def dataProviderFileCourse(uniqname, termid, data_provider_file_directory)
    logger.debug "#{__method__}: #{__LINE__}: data provider is DataProviderFileCourse uniqname: #{uniqname} termid: #{termid}."

    data_file = "#{data_provider_file_directory}/#{uniqname}.#{termid}.json"
    data_file = "#{data_provider_file_directory}/#{uniqname}.json" unless File.exists?(data_file)

    return getWrappedDiskFile(data_file)
  end


# The ESB terms request is /Students/{uniqname}/Terms.  The file provider will
# check the uniqname but will have a default file since usually the terms will be
# the same for the majority of students.

  #def dataProviderFileTerms(uniqname, data_provider_file_directory)
  def dataProviderFileTerms(data_provider_file_directory, uniqname)
    logger.debug "#{__method__}: #{__LINE__}: data provider is DataProviderFile. uniqname: #{uniqname} directory: #{data_provider_file_directory}"

    # get a file name to the data file
    data_file = "#{data_provider_file_directory}/#{uniqname}.json"
    # use a default file if specific one doesn't exist.
    data_file = "#{data_provider_file_directory}/default.json" unless File.exists?(data_file)

    return getWrappedDiskFile(data_file)
  end

# List of the events for a user.

  def dataProviderFileToDoLMS(uniqname, data_provider_file_directory)
    logger.debug "#{__method__}: #{__LINE__}: data provider is DataProviderFile. uniqname: #{uniqname} directory: #{data_provider_file_directory}"

    # get a file name to the data file
    data_file = "#{data_provider_file_directory}/#{uniqname}.json"
    # use a default file if specific one doesn't exist.
    data_file = "#{data_provider_file_directory}/default.json" unless File.exists?(data_file)

    return getWrappedDiskFile(data_file)
  end

# The check call will return the results for a request that is done with a single
# configured user and term.  This allows safely running the check via URL for external monitoring
# without requiring authentication.

  def dataProviderFileCheck(uniqname,data_provider_file_directory)
    uniqname = @@default_uniqname if (uniqname.nil?)
    return dataProviderFileCourse(uniqname, @@default_term, data_provider_file_directory)
  end


  def getWrappedDiskFile(data_file)
    logger.debug "#{__method__}: #{__LINE__}: DPFC: data file string: "+data_file
    if File.exists?(data_file)
      logger.debug "#{__method__}: #{__LINE__}: DPFC: file exists: #{data_file}"
      classes = File.read(data_file)

      wrapped = WAPIResultWrapper.value_from_json(classes);

      # if it isn't valid then just wrap what did come back.
      unless wrapped.valid?
        wrapped = WAPIResultWrapper.new(200, "found file #{data_file}", classes)
      end

    else
      logger.debug "#{__method__}: #{__LINE__}: DPFC: file does not exist: #{data_file}"
      wrapped = WAPIResultWrapper.new(404, "File not found", "Data provider from files did not find a matching file for #{data_file}")
    end

    logger.debug "#{__method__}: #{__LINE__}: DPFC: returning: "+wrapped.to_s
    return wrapped
  end

end
