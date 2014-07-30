$: << File.expand_path('../..', __FILE__)

require 'address-book'
require 'rack/test'

def app
  AddressBook.new
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
