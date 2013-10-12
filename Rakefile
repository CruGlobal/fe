begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake' if File.exists? 'spec/dummy/Rakefile'

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task" 
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end
task default: :spec

ENV['DUMMY_PATH'] = 'spec/dummy'
ENV['ENGINE'] = 'qe_engine'
# ENV['TEMPLATE']
require 'rails/dummy/tasks'

require 'FileUtils'
task :setup_dummy_app do 
  FileUtils.remove_dir("spec/dummy", force=true) if Dir.exists? "spec/dummy"
  
  # Use system here (rather than Rake::Task['task'].invoke) so a new rails env
  # is created, in which the dummy app's module name is no longer present.
  # If we did, Rake::Task["task"].invoke, the dummy app would not be created
  # because the "deleted" spec/dummy would still have it's "Dummy" rails app name
  # in the Ruby's VM environment.
  # 
  system("ENV['DISABLE_MIGRATE']=true ENV['DISABLE_CREATE']=true rake dummy:app ")
  
  # Bring in the customized mysql/postgres testing database.yml.
  File.delete("spec/dummy/config/database.yml")
  FileUtils.cp("spec/support/database.txt",  "spec/dummy/config/database.yml")
  
  Rake::Task["install_engine"].invoke
end

task :install_engine do 
  Rake::Task["app:db:create"].invoke
  
  # Use system (rather than Rake::Task["task"].invoke) so that we 
  # funcitonally test the install generator.
  system("cd spec/dummy && rails g qe:install && rake db:test:prepare")
end
