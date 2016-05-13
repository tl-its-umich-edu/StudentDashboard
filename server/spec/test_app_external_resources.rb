# Verify that can get external resources back from the application.

ENV['RACK_ENV'] = 'test'

require 'rest-client'
require 'yaml'
require_relative '../courselist'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'rack/test'
require 'logger'

require_relative 'test_helper'

class AppExternalResourcesTest < Minitest::Test
  include Rack::Test::Methods
  include Logging

  # some resources files currently available for testing.
  @@expected_image_file = 'UMIngallMallFountan_3253_5.jpg'
  #@@expected_text_file = "1.txt"

  # Test course list application
  def app
    # TODO: set logging level shouldn't be a class method.
    CourseList.setLoggingLevel "ERROR"
    CourseList.new
  end

  def test_get_external_directory_list
    skip("Need to fix ldap issue")
    correct_list = ["image", "text"]

    get '/external'

    assert last_response.ok?, "show two directories"
    assert_equal correct_list, JSON.parse(last_response.body), "list external subdirectories"
  end


  def test_get_external_directory_list_trailing_slash
    skip("need to fix ldap issue")
    correct_list = ["image", "text"]

    get '/external/'

    assert last_response.ok?, "show two directories"
    assert_equal correct_list, JSON.parse(last_response.body), "list external subdirectories"
  end

  def test_get_external_directory_list_invalid_directory
    skip("need to fix ldap issue")
    get '/external/noDirectoryHere'

    assert last_response.forbidden?, "invalid directory forbidden"
  end

  def test_get_external_image_directory_list

    skip("need to fix ldap issue")
    get '/external/image'

    assert last_response.ok?, "get image directory"
    # make sure we find a file we expect to find.
    assert_includes JSON.parse(last_response.body), @@expected_image_file, "find expected image"
  end

  def test_get_external_image_directory_list_trailing_slash
    skip("need to fix ldap issue")
    get '/external/image/'

    assert last_response.ok?, "get image directory"
    # make sure we find a file we expect to find.
    assert_includes JSON.parse(last_response.body), @@expected_image_file, "find expected image"
  end

  def test_retrieve_external_image_file
    skip("need to fix ldap issue")
    use_file = "/external/image/#{@@expected_image_file}"
    get use_file

    assert last_response.ok?
    content_type = last_response.header['Content-Type']

    body = last_response.body

    # It would be hard and not worth it to verify that actually is an image.
    # We do check that it is a plausible image file.

    assert_match "image/jpeg", content_type, "get jpg file type"
    assert_operator 15000, :<, body.length, "get image file"
  end

  #### We're testing both text and image directories / files so we can know
  #### that they are treated differently.

  # def test_get_external_text_directory_list
  #
  #
  #   get '/external/text'
  #
  #   assert last_response.ok?
  #   assert_includes  JSON.parse(last_response.body),@@expected_text_file, "find expected text file"
  # end


  # def test_retrieve_external_text_file
  #
  #   get '/external/text/1.txt'
  #
  #   assert last_response.ok?,"got response from request"
  #   body = last_response.body
  #   content_type = last_response.header['Content-Type']
  #
  #   # Check that is likely is a text file.
  #   assert_match "text/plain",content_type, "get text file"
  #   assert_operator  body.length, :>, 100 ,"get text file"
  # end

end
