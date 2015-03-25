module DataProviderFile

  require_relative 'WAPI_result_wrapper'

###### File provider ################
### Return the data for a request from a matching file.  The file will be in the
### directory specified.
### The name of the file must be <name>.json.  The <name> will be the user name.
### For testing this need not be a uniqname but can be anyname that maps to a file.
### The url localhost:3000/courses/abba.json would map to a file named abba.json in the
### specified directory under the default test-files directory.

  def dataProviderFileCourse(uniqname, termid, data_provider_file_directory)
    logger.debug "data provider is DataProviderFileCourse.\n"

    data_file = "#{data_provider_file_directory}/#{uniqname}.#{termid}.json"

    data_file = "#{data_provider_file_directory}/#{uniqname}.json" unless File.exists?(data_file)

    return getWrappedDiskFile(data_file)
  end


# The ESB terms request is /Students/{uniqname}/Terms.  The file provider will
# check the uniqname but will have a default file since usually the terms will be
# the same for the majority of students.

  def dataProviderFileTerms(uniqname, data_provider_file_directory)
    logger.debug "data provider is DataProviderFileCourse.\n"

    # get a file name to the data file
    data_file = "#{data_provider_file_directory}/#{uniqname}.json"
    # use a default file if specific one doesn't exist.
    data_file = "#{data_provider_file_directory}/default.json" unless File.exists?(data_file)

    return getWrappedDiskFile(data_file)
  end

  def getWrappedDiskFile(data_file)
    logger.debug "#{__LINE__}: DPFC: data file string: "+data_file
    if File.exists?(data_file)
      logger.debug "#{__LINE__}: DPFC: file exists: #{data_file}"
      data = File.read(data_file)
      data = WAPIResultWrapper.new(200, "found file #{data_file}", data).value_as_json
    else
      logger.debug "#{__LINE__}: DPFC: file does not exist: #{data_file}"
      data = WAPIResultWrapper.new(404, "File not found", "Data provider from files did not find a matching file for #{data_file}").value_as_json
    end

    logger.debug "#{__LINE__}: DPFC: returning: "+data
    data_json = WAPIResultWrapper.value_from_json(data)
    return data_json
  end

end
