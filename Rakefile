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
# ENV['ENGINE']
# ENV['TEMPLATE']

task :setup_dummy_app do 
  # Nuke any previous testing envs (for local development purposes).
  Rake::Task["app:db:drop"].invoke if Dir.exists? "spec/dummy"
  FileUtils.remove_dir("spec/dummy", force=true) if Dir.exists? "spec/dummy"
  
  # Use system here (rather than Rake::Task['task'].invoke) so a new rails env
  # is created, in which the dummy app's module name is no longer present.
  # If we did, Rake::Task["task"].invoke, the dummy app would not be created
  # because the "deleted" spec/dummy would still have it's "Dummy" rails app 
  # name in the Ruby VM environment.
  #
  system({"DISABLE_MIGRATE" => "true", "DISABLE_CREATE" => "true"}, "rake dummy:app")
  
  # Bring in the customized mysql/postgres testing database.yml.
  File.delete("spec/dummy/config/database.yml")
  FileUtils.cp("spec/support/database.txt",  "spec/dummy/config/database.yml")
  
  Rake::Task["install_engine"].invoke
end

task :install_engine do 
  # Use system so that we load the dummy app's Rake commands.
  system("rake app:db:create")
  
  # Use system so that we funcitonally test the install generator.
  system("cd spec/dummy && rails g fe:install && rake db:migrate && rake db:test:prepare")
end
