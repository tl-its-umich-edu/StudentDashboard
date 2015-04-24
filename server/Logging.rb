require 'logger'

# Based on suggestion in: https://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes
# incorporate via 'include logging'

module Logging
  class << self
    def logger
      @logger ||= Logger.new($stdout)
    end

    def logger=(logger)
      @logger = logger
    end
  end

  # Addition
  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    Logging.logger
  end

  # Trim could be generalized if needed
  def self.trimBackTraceRVM(backTraceArray)
    backTraceArray.reject {|s| s.match(/.rvm/) }
  end
end
