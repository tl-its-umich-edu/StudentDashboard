require 'simplecov'
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
