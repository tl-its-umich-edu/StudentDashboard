# Integration test to verify that a user can be found in
# an MCommunity group if they are present.
require_relative 'test_helper'
require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'logger'
require_relative '../../server/Logging'

## set the environment for testing
#ENV['RACK_ENV'] = 'test'

require 'net-ldap'

require_relative '../ldap_check'

class LdapTest < MiniTest::Test
  include Logging

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # by default assume the tests will run well and don't need
    # to have detailed log messages.
    logger.level = Logger::ERROR
    #logger.level = Logger::DEBUG
    #@group = "ctsupportstaff"
    @group = "TL-Latte-admin-test"
    @x = LdapCheck.new('group' => @group)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_constructor_config_value_access
    lc = LdapCheck.new({})
    conf = lc.configuration
    assert_equal(389,conf["port"], "can get value from config file")
  end

  def test_constructor_config_value_override
    lc = LdapCheck.new({"port"=>"HOWDY"})
    conf = lc.configuration
    assert_equal("HOWDY",conf["port"], "can override default config file value")
  end

  ## test to see if the membership query finds person that is in group
  def test_dlhaines_ctsupport
    assert @x, "have ldap check object"
    #found = @x.checkMemberInGroup("dlhaines","ctsupportstaff")
    #found = @x.checkMemberInGroup("dlhaines",@group)
    found = @x.is_user_in_admin_hash "dlhaines"
    assert found,"checking member in group"
  end

  ## test if it does not find person not in group
  def test_GODZILLA_XXX_ctsupport
    assert @x, "have ldap check object"
    #found = @x.checkMemberInGroup("GODZILLA_XXX","ctsupportstaff")
    #puts "@group: #{@group}"
    #found = @x.checkMemberInGroup("GODZILLA_XXX",@group)
    found = @x.is_user_in_admin_hash "GODZILLA_XXX"
    refute found,"checking GOZILLA_XXX in group"
  end

  # def test_memberFilter
  #   m = LdapCheck.new({"filter_prefix" => "FIRST", "filter_suffix" => "LAST"})
  #   f = @x.memberFilter("them")
  #   assert_equal("(&(cn=them) (objectclass=rcf822MailGroup))",f,"build correct member filter")
  # end

  #def test_yml
#
#  end

  # # GET THE DISPLAY NAME AND E-MAIL ADDRESS FOR A SINGLE USER
  # search_param = "lstarr"
  # result_attrs = ["sAMAccountName", "displayName", "mail"]
  #
  # # Build filter
  # search_filter = Net::LDAP::Filter.eq("sAMAccountName", search_param)
  #
  # # Execute search
  # ldap.search(:filter => search_filter, :attributes => result_attrs, :return_result => false) { |item|
  #   puts "#{item.sAMAccountName.first}: #{item.displayName.first} (#{item.mail.first})"
  # }
  #

  #F='(&(cn=ctsupportstaff)(objectclass=rfc822MailGroup))'
  #ldapsearch -H ldap://ldap.itd.umich.edu:389 -D"ou=Groups,dc=umich,dc=edu" -L $F member
  # filter: '(&(member=uid=dlhaines,ou=People,dc=umich,dc=edu)(cn=its tl staff))'

  def find_user_in_ldap_members user, members
    puts "user: #{user} members: #{members}"
    found = false
    members.each { |e| found = true if e.start_with? "uid=#{user}," }
    found
  end

  def test_constructor_config_value_override
    lc = LdapCheck.new({"port"=>"HOWDY"})
    conf = lc.configuration
    assert_equal("HOWDY",conf["port"], "can override default config file value")
  end

  ## test to see if the membership query finds person that is in group
  def test_dlhaines_ctsupport
    assert @x, "have ldap check object"
    #found = @x.checkMemberInGroup("dlhaines","ctsupportstaff")
    #found = @x.checkMemberInGroup("dlhaines",@group)
    found = @x.is_user_in_admin_hash "dlhaines"
    assert found,"checking member in group"
  end

  ## test if it does not find person not in group
  def test_GODZILLA_XXX_ctsupport
    assert @x, "have ldap check object"
    #found = @x.checkMemberInGroup("GODZILLA_XXX","ctsupportstaff")
    puts "@group: #{@group}"
    #found = @x.checkMemberInGroup("GODZILLA_XXX",@group)
    found = @x.is_user_in_admin_hash "GODZILLA_XXX"
    refute found,"checking GOZILLA_XXX in group"
  end

end
