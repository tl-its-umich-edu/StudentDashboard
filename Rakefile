require 'rake/testtask'

### TTD
# - add tests invocation.
# - check that build has been done?  Invoke if necessary?


######################################################
## commands to setup and run vagrant VM with Dashboard

namespace :vagrant do
  desc "Starts Vagrant VM"
  task :up do
    sh "(cd vagrant; vagrant up)"
  end

  desc "destroys vagrant VM"
  task :destroy do
    sh "(cd vagrant; vagrant destroy -f)"
  end

  desc "halt vagrant VM"
  task :halt do
    sh "(cd vagrant; vagrant halt)"
  end
  
  desc "open xterm to the vagrant VM"
  task :xterm do
    sh "(cd vagrant; ./vagrantXterm.sh)"
  end
end


# ## default unit tests
# Rake::TestTask.new do |t|
#   t.libs << "test"
#   t.test_files = FileList['**/test_*.rb'].exclude('**/test_integration*rb')
#   t.verbose = true
# end

# ## integration tests, only done on request.
# Rake::TestTask.new do |t|
#   t.libs << "test"
#   t.name = "test_integration"
#   t.test_files = FileList['**/test_integration*.rb']
#   t.verbose = true
# end

## end
