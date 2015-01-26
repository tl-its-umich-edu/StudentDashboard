# Operations with LDAP.

require 'net-ldap'
require 'yaml'
require_relative '../server/Logging'

class LdapCheck
  include Logging

  ## setup ldap connection object
  def initialize(args={})

    @default_conf_file = "./server/spec/ldap.yml"
    conf_file_name = args[:conf_file] || @default_conf_file

    # if file is missing trap the "no such file" exception
    begin
      conf_values = YAML.load_file(conf_file_name)
      rescue => exp
    end

    #h.each_key {|key| puts key }
    puts "yml"
    p conf_values

    conf_values.each_key {| k | puts "key: [#{k}] value: [#{conf_values[k]}]"}

    # make an empty configuration if the file is empty
    # conf_values = Hash.new unless conf_values
    #
    # @host = args["host"] || conf_values["host"]
    # @port = args["port"] || conf_values["port"]
    # @encryption = args["encryption"] || conf_values["encryption"]
    # @base = args["base"] || conf_values["base"]
    #
    # @ldap_dc = args["ldap_dc"] || conf_values["ldap_cd"]
    # @search_base = args["search_base"] || conf_values["search_base"]
    # @filter_prefix = args["filter_prefix"] || conf_values["filter_prefix"]
    # @filter_suffix = args["filter_suffix"] || conf_values["filter_suffix"]
    #
    # ## auth should contain credentials hash of :method, :username, :password
    # @auth = args["auth"] || conf_values["auth"]

  end

  # setup a filter to get members
  ## these from jsp
  ## attrIDs = "member"
  ## filter = "(&(cn="+grp+") (objectclass=rfc822MailGroup))"
  ## subtree scope
  ## returningAttr attrIDs
  ## searchBase "ou=Groups"
  ## search on searchbase, filter, ctls) (ctls is search controls)
  def memberFilter(grp)
    "#{@filter_prefix}#{grp}#{@filter_suffix}"
  end

  # check if this user is a member
  def memberCheck(user)
    # pass the search and filter and get back

  end
end
