require 'logger'

# Based on suggestion in: https://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes
# incorporate via 'include Logging'

#Log.formatter = proc { |severity, datetime, progname, msg|
#  "#{severity} #{caller[4]} #{msg}\n"
#}

module Logging
  class << self
    def logger
      @logger ||= Logger.new($stdout)
    end

    def logger=(logger)
      @logger = logger
    end
  end

  # Run when the module is included
  def self.included(base)
    class << base
      def logger
        Logging.logger
      end

      ## setup the new formatter for the logs
      #    Logging.logger.formatter = proc { |severity, datetime, progname, msg|
      #       "#{severity} #{caller[4]} #{msg}\n"
      #     }

      #      Logging.logger.formatter = proc { |severity, datetime, progname, msg|
      #              "#{severity[0..0]}, [#{datetime}] #{severity} #{caller[4]} #{msg}\n"
      #            }

      # default Log format:
      #   SeverityID, [Date Time mSec #pid] SeverityLabel -- ProgName: message
      #
      # Log sample:
      #   I, [Wed Mar 03 02:34:24 JST 1999 895701 #19074]  INFO -- Main: info.

    end
  end

  def logger
    Logging.logger
  end

  # Trim could be generalized if needed
  def self.trimBackTraceRVM(backTraceArray)
    backTraceArray.reject { |s| s.match(/.rvm/) }
  end

end
