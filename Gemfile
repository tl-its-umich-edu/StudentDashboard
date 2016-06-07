source 'https://rubygems.org'
# Check ruby version to set requirements.
# Default to this to recent jruby
#ruby '2.3.0', engine: 'jruby', engine_version: '9.1.0.0'
ruby '1.9.3', engine: 'jruby', engine_version: '1.7.18' if RUBY_VERSION =~ /1.7.18/
ruby '1.9.3', engine: 'jruby', engine_version: '1.7.24' if RUBY_VERSION =~ /1.7.24/
ruby '1.9.3', engine: 'jruby', engine_version: '1.7.25' if RUBY_VERSION =~ /1.7.25/
gem 'sinatra'
gem 'sinatra-contrib'
gem 'slim'
gem 'rack'
gem 'rack-protection'
gem 'rest-client'
gem 'link_header'
gem 'net-ldap', '<= 0.12.1'
gem 'rake'
gem 'warbler', '<2.0.0'
group :development do
#  gem 'guard'
#  gem 'listen'
#  gem 'rb-inotify', :require => false
#  gem 'rb-fsevent', :require => false
end
group :test do
  gem 'simplecov', :require => false, :group => :test
  gem 'rack-test'
  gem 'rspec'
  gem 'minitest'
  gem 'webmock', '< 2'
  gem 'selenium-webdriver'
end
