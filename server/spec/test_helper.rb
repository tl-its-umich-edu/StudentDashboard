require 'simplecov'

## The SD Logger class must be required before including this TestHelper class.
## It should NOT be included directly in a test class itself.  It should be included
## by including the class under test.

SimpleCov.start do
  filters.clear
  add_filter "/.rvm/"
  add_filter "/RubyMine.app/"
  add_filter do |source_file|
    false
  end

  class TestHelper < Object

    ## return a fully qualified path to the test file directory
    ## It assumes standard locations and looking for directory with name 'test-files'
    def self.findTestFileDirectory
      currentDirectory = Dir.pwd()

      checkDir = "#{currentDirectory}/server/test-files"
      return checkDir if Dir.exist?(checkDir);

      checkDir = File.dirname(currentDirectory)+"/test-files"
      return checkDir if Dir.exist?(checkDir);

      puts "CAN NOT FILE TEST FILE DIRECTORY: ";
      exit 1
    end

    ## return a fully qualified path to the directory with the security file.
    ## It assumes standard locations of current directory, or sub directory
    ## starting with '/server/spec/'
    def self.findSecurityFile(file_name)
      currentDirectory = Dir.pwd()

      checkFile = "#{currentDirectory}/#{file_name}"
      return checkFile if File.exist?(checkFile);

      checkFile = currentDirectory+"/server/spec/#{file_name}"
      return checkFile if File.exist?(checkFile);

      puts "CAN NOT FIND SECURITY FILE: #{file_name}";
      exit 1
    end


  end
end

include Logging

class TestHelper < Object

  # store a global default log level that test files can
  # look up and share.
  @@log_level = Logger::Severity::WARN
  #@@log_level  = Logger::Severity::DEBUG

  def self.getCommonLogLevel
    return @@log_level
  end

  ## return a fully qualified path to the test file directory
  ## It assumes standard locations and looking for directory with name 'test-files'
  def self.findTestFileDirectory
    currentDirectory = Dir.pwd()

    checkDir = "#{currentDirectory}/server/test-files"
    return checkDir if Dir.exist?(checkDir);

    checkDir = File.dirname(currentDirectory)+"/test-files"
    return checkDir if Dir.exist?(checkDir);

    # didn't find anything.
    puts "CAN NOT FIND TEST FILE DIRECTORY: ";
    exit 1
  end

  ## return a fully qualified path to the directory with the security file.
  ## It assumes standard locations and looking for directory with name 'test-files'
  def self.findSecurityFile(file_name)
    currentDirectory = Dir.pwd()

    checkDir = "#{currentDirectory}/#{file_name}"
    return checkDir if File.exist?(checkDir);

    checkDir = currentDirectory+"/server/spec/#{file_name}"
    return checkDir if File.exist?(checkDir);

    puts "CAN NOT FIND SECURITY FILE: #{file_name}";
    exit 1
  end

end
