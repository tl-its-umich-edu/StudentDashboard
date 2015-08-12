ENV['RACK_ENV'] = 'test'

require 'rest-client'
require_relative '../courselist'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'rack/test'

class HelloWorldTest < Minitest::Test
  include Rack::Test::Methods

  # Test course list application
  def app
    # TODO: set logging level shouldn't be a class method.
    CourseList.setLoggingLevel "WARN"
    CourseList.new
  end

  def test_get_external_directory_list
    correct_list = ["image", "text"]

    get '/external'

    assert last_response.ok?, "show two directories"
    assert_equal  correct_list, JSON.parse(last_response.body),"list external subdirectories"
  end


  def test_get_external_directory_list_trailing_slash
    correct_list = ["image", "text"]

    get '/external/'

    assert last_response.ok?, "show two directories"
    assert_equal  correct_list, JSON.parse(last_response.body),"list external subdirectories"
  end

  def test_get_external_directory_list_invalid_directory

    get '/external/noDirectoryHere'

    assert last_response.forbidden?
  end

   def test_get_external_image_directory_list
    correct_list = ["black.png", "blue.png", "green.png", "magenta.png", "miro.png", "red.png", "yellow.png"]

    get '/external/image'

    assert last_response.ok?
    assert_equal  correct_list, JSON.parse(last_response.body),"list images"
  end

  def test_get_external_image_directory_list_trailing_slash
    correct_list = ["black.png", "blue.png", "green.png", "magenta.png", "miro.png", "red.png", "yellow.png"]

    get '/external/image/'

    assert last_response.ok?
    assert_equal  correct_list, JSON.parse(last_response.body),"list images"
  end

  def test_get_external_image_file

    get '/external/image/green.png'

    assert last_response.ok?
    body = last_response.body

    # It would be hard and not worth it to verify that actually is an image.
    # We do check that it is a plausible image file.
    assert_operator  15000, :<, body.length ,"get image file"
  end

  #### We're testing both text and image directories / files so we can know
  #### that they are treated differently.

  def test_get_external_text_directory_list
    correct_list = ["howdy.txt"]

    get '/external/text'

    assert last_response.ok?
    assert_equal  correct_list, JSON.parse(last_response.body),"list text files"
  end


  def test_get_external_text_file

    get '/external/text/howdy.txt'

    assert last_response.ok?
    body = last_response.body

    # Check that is likely is a text file.
    assert_operator  100, :>, body.length ,"get image files"
  end


end
