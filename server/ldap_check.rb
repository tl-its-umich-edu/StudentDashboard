# Operations with LDAP.  Currently only supports getting default configuration values
# and checking if a user is in a particular mcommunity group.
# A configuration file name can be passed in when creating the object.  The default
# value is ./server/local/ldap.yml.

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
    p args
    conf_file_name = args["config_file"] || @default_conf_file

    # if file is missing then trap the "no such file" exception
    begin
      @conf_values = YAML.load_file(conf_file_name)
    rescue => exp
      logger.info("can not find ldap config file: #{conf_file_name}")
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

    if logger.debug?
      logger.debug "final conf values"
      @conf_values.each_key { |k| logger.debug "key: [#{k}] value: [#{@conf_values[k]}]" }
    end

    ## save members in this group if one is specified.
    save_group_members args['group'] if args['group']

  end


  # this provides access to verify / debug configuration.
  def configuration
    @conf_values
  end

  # See if the specified user is in the list of members which was provided by
  # the LDAP call to MCommunity.

  def is_user_in_admin_hash user
    logger.debug "admin user check: user: #{user} key: " + @admin_hash.has_key?(user).to_s

    @admin_hash.has_key? user
  end

  def add_to_members_hash members
    regex_user = /uid=([^,]+),/;

    @admin_hash = Hash.new() if @admin_hash.nil?

    members.each do |m|
      u = regex_user.match(m)[1].to_s
      # do not want to provide a default value since most queries
      # will be about entries that aren't there.
      @admin_hash[u] = 0 unless @admin_hash.has_key? u
      @admin_hash[u] = @admin_hash[u] + 1
    end

  end


  def save_group_members(group)

    # Note that the hash returned for yaml uses strings for keys
    # so we adopt that approach throughout except for the call
    # to net-ldap where the keys are expected to be symbols.

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

      add_to_members_hash groupData[0].member
    end

  end

end
