module DataProviderFile
###### File provider ################
### Return the data from a matching file.  The file must be in a sub-directory
### under the directory specified by the property data_file_dir.
### The sub-directory will be the name of the type of data requested (e.g. courses)
### The name of the file must match the rest of the URL.
### E.g. localhost:3000/courses/abba.json would map to a file named abba.json in the 
### courses sub-directory under, in this case, the test-files directory.
  def DataProviderFileCourse(a, termid, data_provider_file_directory)
    logger.debug "data provider is DataProviderFileCourse.\n"

    data_file = "#{data_provider_file_directory}/#{a}.json"
    logger.debug "data file string: "+data_file

    if File.exists?(data_file)
      logger.debug("file exists: #{data_file}")
      classes = File.read(data_file)
    else
      logger.debug("file does not exist: #{data_file}")
      classes = "404"
    end

    logger.debug("returning: "+classes)
    return classes
  end
end
