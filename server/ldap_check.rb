# Operations with LDAP.  Currently only supports getting default configuration values
# and checking if a user is in a particular mcommunity group.
# A configuration file name can be passed in when creating the object.  The default
# value is ./server/local/ldap.yml.
# The members of the MCommunity group will be read on startup.  Changes in membership will
# not be recognized until the application is restarted.

require 'net-ldap'
require 'yaml'
require_relative '../server/Logging'

class LdapCheck
  include Logging

  ## Setup the ldap connection object and save the members of the group.

  def initialize(args={})

    # This file will be provided in the build with values
    # suitable for the MCommunity groups.
    @default_conf_file = "./server/local/ldap.yml"
    @default_cache_seconds = 300
    conf_file_name = args["config_file"] || @default_conf_file

    # keep track for caching
    @lastUpdate = Time.at(0)
    # allow checking how often update happens for testing and tuning.
    @updateCount = 0

    # if file is missing then trap the "no such file" exception
    begin
      @conf_values = YAML.load_file(conf_file_name)
    rescue => exp
      logger.error("can not find ldap config file: #{conf_file_name}")
      raise LdapCheckError, "missing configuration file: #{conf_file_name}"
    end

    # Note that the hash returned for yaml uses strings for keys
    # so we adopt that approach throughout except for the call
    # to net-ldap where the keys are expected to be symbols.

    # If yml didn't create a hash make sure there is one now.
    @conf_values = Hash.new unless @conf_values

    # overwrite the default config values with ones from the arguments if there
    # are any.
    args.each_key { |k|
      @conf_values[k] = args[k]
    }

    configuration['cache_seconds'] = @default_cache_seconds unless (configuration['cache_seconds'])

    if logger.debug?
      logger.debug "final conf values"
      configuration.each_key { |k| logger.debug "key: [#{k}] value: [#{configuration[k]}]" }
    end

  end


  # Provide access to configuration hash
  def configuration
    @conf_values
  end

  # provide access to count of LDAP update calls
  def updateCount
    @updateCount
  end

  # See if the specified user is in the list of members which was provided by
  # the LDAP call to MCommunity.

  def is_user_in_admin_hash user

    return nil unless configuration['group']
    logger.debug "#{self.class.to_s}:#{__method__}:#{__LINE__}: admin user check: user: #{user}"

    # if the cache has expired then update the group members.
    timeFromLastUpdate = Time.now() - @lastUpdate
    if timeFromLastUpdate > configuration['cache_seconds']
      logger.info "#{self.class.to_s}:#{__method__}:#{__LINE__}: updating ldap_check admin hash"
      @updateCount += 1
      @lastUpdate = Time.now()
      # if resetting the values get rid of the set of members.
      @admin_hash = nil;
      save_group_members configuration['group']
      # Might get a group with no members or that doesn't exist.
      @admin_hash = Hash.new unless (@admin_hash)
    end

    @admin_hash.has_key? user
  end

  def add_to_members_hash members
    regex_user = /uid=([^,]+),/;

    # make sure there is a hash to put things in.
    @admin_hash = Hash.new() if @admin_hash.nil?

    members.each do |m|
      u = regex_user.match(m)[1].to_s
      @admin_hash[u] = 1
    end

  end

  def save_group_members(group)

    # Note that the hash returned for yaml uses strings for keys
    # so we adopt that approach throughout except for the call
    # to net-ldap where the keys are expected to be symbols.

    logger.debug "update admin members from MCommunity"

    conf = configuration
    host = conf["host"]
    port = conf["port"]
    search_base = conf["search_base"]

    Net::LDAP.open(:host => host,
                   :port => port,
                   :base => search_base) do |ldap|

      # Get the members of the group
      filterString = "(&(cn=#{group})(objectclass=rfc822MailGroup))"
      groupFilter = Net::LDAP::Filter.construct(filterString)
      groupData = ldap.search(:filter => groupFilter)

      # If there is a problem accessing the group data then the user can't
      # be considered an admin.
      begin
        add_to_members_hash groupData[0].member
      rescue StandardError => e
        logger.info "error reading admin members group: #{e}"
        return nil
      end

    end

  end

end

# This empty class implements a named exception.
class LdapCheckError < StandardError
end
