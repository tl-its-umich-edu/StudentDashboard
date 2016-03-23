# Handle calls to external resources found in a file system like arrangement.
# The constructor takes the base name of a resources directory.  All other references
# will be relative to this.

# The constructor takes a string specifying the base directory containing sub-directories and files.
# the get_resource call takes a sub directory and an explicit file name.
# A nil sub-directory defaults to the directory specified in the constructor.
# A nil resource file name indicates that this is a request to get a listing of files in the specified directory.

# The possible return values are:
# nil - when the resource can't be accessed.
# json array of file names (or sub directories)- when a directory listing is requested.
# binary - when a requested file is found.

# If a resource is missing or an error occurs then a message will be logged and nil will be returned.

### TTD:
# - remove list_resources?

require 'json'
require_relative '../server/Logging'

class ExternalResourcesFile
  include Logging

  attr_accessor :resources_base_directory

  ######### public methods #########
  # Argument supplied is the base directory under which all resources are stored.
  def initialize(directory)
    @resources_base_directory = directory
  end

  # The parameters are the directory levels under the base directory given at initialize and the file name of the
  # specific resource.  If the resource_name is null then the request is treated as a directory listing.
  def get_resource(sub_directory, resource_name=nil)
    use_directory = sub_directory.nil? ? @resources_base_directory : "#{@resources_base_directory}/#{sub_directory}"
    begin
      return getExternalResource(use_directory, resource_name)
    rescue => exp
      logger.warn "External resource error: #{exp}"
      logger.warn "current directory: "+Dir.pwd.to_s
    end
    return nil
  end

  ############### private methods ###################
  # These don't know about the instance variables.  These are private so that
  # the implementation specific method names can't creep into the code using this.
  private
  def getDirList (directory)
    logger.debug("external resource: listing directory: #{directory}")
    Dir.new(directory).to_a.select { |f| f !~ /^\.\.?$/ }.to_json
  end

  private
  def getFile (filePath)
    logger.debug("external resource: getting file: #{filePath}")
    IO.read(filePath)
  end

  private
  def getExternalResource(directory, file_name)
    (file_name.nil? || file_name.length == 0) ? getDirList(directory) : getFile("#{directory}/#{file_name}")
  end

end
