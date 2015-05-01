# Integration test to verify that a user can be found in
# an MCommunity group if they are present.
require_relative 'test_helper'
require 'rubygems'
require 'minitest'
require 'minitest/autorun'
require 'minitest/unit'
require 'logger'
require_relative '../../server/Logging'

require 'net-ldap'

require_relative '../ldap_check'

REAL_USER = "dlhaines"

class LdapTest < MiniTest::Test
  include Logging

  # Test ldap functionality.  Note that calls real ldap group with real user
  # so if those change then the results may change.

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # by default assume the tests will run well and don't need
    # to have detailed log messages.
    #logger.level = Logger::ERROR
    #logger.level = Logger::INFO
    #logger.level = Logger::DEBUG
    @group = "TL-Latte-admin-test"

    # config_file has a default.  Use this file path instead if the path leads
    # to a file. This makes it possible to run the tests from different directories.
    @config_file = '../local/ldap.yml' if File.exists?('../local/ldap.yml')
    @x = LdapCheck.new('group' => @group, 'config_file' => @config_file)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_throw_error_missing_config_files
    assert_raises(LdapCheckError) do
      lc = LdapCheck.new({'config_file' => 'MamaAndPappasMakeDinner'})
    end
  end

  def test_constructor_config_value_access
    lc = LdapCheck.new({'config_file' => @config_file})
    conf = lc.configuration
    assert_equal(389, conf["port"], "can get value from config file")
  end

  def test_constructor_config_value_override
    lc = LdapCheck.new({"port" => "HOWDY", 'config_file' => @config_file})
    conf = lc.configuration
    assert_equal("HOWDY", conf["port"], "can override default config file value")
  end

  def test_constructor_config_file_value_override
    @x = LdapCheck.new('group' => @group, 'config_file' => @config_file, 'cache_seconds' => 10)
    assert_equal(10,@x.configuration['cache_seconds'],"override value in config file")
    @x = LdapCheck.new('group' => @group, 'config_file' => @config_file, 'cache_seconds' => 7)
    assert_equal(7,@x.configuration['cache_seconds'],"override value in config file")
  end

  ## test to see if the membership query finds person that is in group


  def test_dlhaines_ctsupport
    assert @x, "have ldap check object"
    found = @x.is_user_in_admin_hash REAL_USER
    assert found, "checking member in group"
  end

  def test_dlhaines_ctsupport_timed_in_one_cache_interval
    @x = LdapCheck.new('group' => @group, 'config_file' => @config_file, 'cache_seconds' => 2)
    assert @x, "have ldap check object"
    found = @x.is_user_in_admin_hash REAL_USER
    assert found, "checking member in group"
    assert_equal 1,@x.updateCount,"one request is one update"
    found = @x.is_user_in_admin_hash REAL_USER
    found = @x.is_user_in_admin_hash REAL_USER
    assert_equal 1,@x.updateCount,"three requests in one cache interval"
    assert found, "checking member in group"
  end

  def test_dlhaines_ctsupport_timed_over_multiple_cache_intervals
    # verify that if cache time is longer than time between requests will get a new update
    # different environments might have different results depending on waits.
    @x = LdapCheck.new('group' => @group, 'config_file' => @config_file, 'cache_seconds' => 2)
    assert @x, "have ldap check object"
    found = @x.is_user_in_admin_hash REAL_USER
    assert found, "checking member in group"
    assert_equal 1,@x.updateCount,"one request is one update"
    sleep 2
    found = @x.is_user_in_admin_hash REAL_USER
    assert_equal 2,@x.updateCount,"request longer than interval A"
    sleep 2
    found = @x.is_user_in_admin_hash REAL_USER
    assert_equal 3,@x.updateCount,"request longer than interval B"
    sleep 2
    found = @x.is_user_in_admin_hash REAL_USER
    assert_equal 4,@x.updateCount,"request longer than interval C"
    assert found, "checking member in group"
  end

  ## test if it does not find person not in group
  def test_GODZILLA_XXX_ctsupport
    assert @x, "have ldap check object"
    found = @x.is_user_in_admin_hash "GODZILLA_XXX"
    refute found, "checking GOZILLA_XXX in group"
  end

  def find_user_in_ldap_members user, members
    found = false
    members.each { |e| found = true if e.start_with? "uid=#{user}," }
    found
  end

end
