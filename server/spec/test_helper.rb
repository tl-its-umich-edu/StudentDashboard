require 'simplecov'
SimpleCov.start do
  filters.clear
  add_filter "/.rvm/"
  add_filter "/RubyMine.app/"
  add_filter do |source_file|
    false
  end
end
