# Do options parsing for Student Dashboard code.  This can
# parse an arguments array or an environment variable.

require 'optparse'
require 'ostruct'

class OptionsParse
  #
  # Return a structure describing the supplied parsed options.
  #

  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options, opts = setupOptionParser

    opts.parse!(args)
    options
  end 


  def self.parseEnvironment(name)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options, opts = setupOptionParser

    opts.environment(name)
    options
  end

  def self.setupOptionParser
    options = OpenStruct.new
    options.config_file = nil

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: courselist.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-c", "--config_dir", "=CONFIG_DIR",
              "Specify a directory in which to find yml configuration file .") do |value|
        options.config_base = value
      end

      # This will print an options summary.  Only used when options parsing fails.
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end
    return options, opts
  end

end

