module DataProviderFile

  require_relative 'WAPI_result_wrapper'
###### File provider ################
### Return the data for a request from a matching file.  The file must be in a sub-directory
### under the directory specified by the property data_file_dir.
### The name of the sub-directory will be the name of the type of data requested (e.g. courses)
### The name of the file must match the rest of the URL.
### The url localhost:3000/courses/abba.json would map to a file named abba.json in the
### courses sub-directory under the default test-files directory.
  def DataProviderFileCourse(a, termid, data_provider_file_directory)
    logger.debug "data provider is DataProviderFileCourse.\n"

    data_file = "#{data_provider_file_directory}/#{a}.json"
    logger.debug "#{__LINE__}: DPFC: data file string: "+data_file

    if File.exists?(data_file)
      logger.debug "#{__LINE__}: DPFC: file exists: #{data_file}"
      classes = File.read(data_file)

      ## treat as prewrapped result

     # puts "DPFC: classes as read: #{classes}"
      wrapped = WAPIResultWrapper.value_from_json(classes);
      puts "verify wrapping type"
      p wrapped

      # if it isn't valid then just wrap what did come back.
      unless wrapped.valid?
        wrapped = WAPIResultWrapper.new(200, "found file #{data_file}", classes)
        puts "DPFC:"
        p wrapped
      end

    else
      logger.debug "#{__LINE__}: DPFC: file does not exist: #{data_file}"
      wrapped = WAPIResultWrapper.new(404, "File not found", "Data provider from files did not find a matching file for #{data_file}")
    end

    logger.debug "#{__LINE__}: DPFC: returning: "+wrapped.to_s
    return wrapped
  end
end
