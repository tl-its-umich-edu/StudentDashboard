require 'rake/testtask'

### TTD
# - vagrant: check that build has been done?  Invoke if necessary?

######################################################
## commands to setup and run vagrant VM with Dashboard
desc "### Commands to setup and run Vagrant VM for Dashboard testing"
task :vagrant

namespace :vagrant do
  desc "Make the application build artifacts available for creating the VM"
  task :get_artifacts do
    sh "(cd vagrant; ./getArtifacts.sh)"
  end

  desc "Starts the Vagrant VM, creating it if necessary"
  task :up => :get_artifacts do
    sh "(cd vagrant; vagrant up)"
  end

  desc "Same as the halt task"
  task :down => :halt

  desc "Stop VM and destroy it"
  task :destroy do
    sh "(cd vagrant; vagrant destroy -f)"
  end

  desc "Halt (stop) the vagrant VM but do not delete it"
  task :halt do
    sh "(cd vagrant; vagrant halt)"
  end

  desc "Open a (debug) xterm to the vagrant VM, YMMV."
  task :xterm do
    sh "(cd vagrant; ./vagrantXterm.sh)"
  end

  desc "Open a ssh terminal connection to the vagrant VM."
  task :ssh do
    sh "(cd vagrant; vagrant ssh)"
  end
end

########## testing tasks #################

desc "### Available tests are test:all, test:local, test:resources, test:integration"
task :test do
  puts "Try rake -t :test"
end

namespace :test do

  desc "available tests are: [:test:local, :test:integration, :test:resources]"
  task :all => [:local, :integration, :resources]

## default unit tests
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.name = "local"
    t.description = "Check local unit tests"
    t.test_files = FileList['**/test_*.rb'].exclude('**/test_integration*rb')
    t.verbose = true
  end

## integration tests, only done on request.
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.name = "integration"
    t.description = "Check using integration with working ESB"
    t.test_files = FileList['**/test_integration*.rb']
    t.verbose = true
  end

## specific tests
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.name = "resources"
    t.description = "Check file implementation of external resources url space"
    t.test_files = FileList['**/test_*resources*.rb']
    t.verbose = true
  end
end

## end
