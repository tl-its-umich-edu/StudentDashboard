# rake file for Student Dashboard

require 'rake/testtask'

## setup tasks to run tests.  Separate out the
## unit and integration tests.

task :tests => ['test_unit','test_integration']

## These TestTask defintions differ in which files are included.
Rake::TestTask.new("test_unit") do |t|
  t.libs << "server"
  t.libs << "server/spec"
  t.test_files = FileList['server/spec/**/test*.rb'].exclude('server/spec/**/*integration*.rb')
  t.verbose = true
end

Rake::TestTask.new("test_integration") do |t|
  t.libs << "server"
  t.libs << "server/spec"
  t.test_files = FileList['server/spec/**/test*integration*.rb']
  t.verbose = true
end


#end
