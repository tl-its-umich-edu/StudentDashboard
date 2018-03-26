source 'https://rubygems.org'
# Check ruby version to set requirements.
# Default to this to recent jruby
ruby '2.3.0', engine: 'jruby', engine_version: '9.1.2.0'
ruby '1.9.3', engine: 'jruby', engine_version: '1.7.18' if RUBY_VERSION =~ /1.7.18/
ruby '1.9.3', engine: 'jruby', engine_version: '1.7.25' if RUBY_VERSION =~ /1.7.25/
gem 'sinatra'
gem 'sinatra-contrib'
gem 'slim'
gem 'rack'
# update for security issue reported by github
gem 'rack-protection', '~> 1.5.5'
# update for security issue reported by github
gem 'rubyzip', '~> 1.2.1'
gem 'rest-client'
gem 'link_header'
#gem 'net-ldap', '<= 0.12.1'
# update for security issue reported by github
gem 'net-ldap'
gem 'jruby-openssl', '>= 0.9.17'
gem 'rake'
group :development do
  gem 'guard'
  gem 'listen'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
end
group :test do
  gem 'simplecov', :require => false, :group => :test
  gem 'rack-test'
  gem 'rspec'
  gem 'minitest'
  gem 'webmock', '< 2'
  gem 'selenium-webdriver'
end
 
