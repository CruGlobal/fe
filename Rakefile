require 'bundler/setup'
require 'thor'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake' if File.exists? 'spec/dummy/Rakefile'


Bundler::GemHelper.install_tasks

ENV['ENGINE'] = 'fe_engine'

require "rspec/core/rake_task" 
RSpec::Core::RakeTask.new(:spec) do |spec|
  unless File.directory?("spec/dummy")
    Rake::Task['dummy:app'].invoke unless ENV['SKIP_DUMMY_APP']
  end
  spec.rspec_opts = "-I #{File.expand_path('../spec/', __FILE__)}"
  spec.pattern = FileList[File.expand_path('../spec/**/*_spec.rb', __FILE__)]
end
task default: :spec


require 'rails/dummy/tasks'

# ENV['ENGINE']
# ENV['TEMPLATE']

task :setup_dummy_app do 
  # Nuke any previous testing envs (for local development purposes).
  FileUtils.remove_dir("spec/dummy", force=true) if Dir.exists? "spec/dummy"
  
  # Use system here (rather than Rake::Task['task'].invoke) so a new rails env
  # is created, in which the dummy app's module name is no longer present.
  # If we did, Rake::Task["task"].invoke, the dummy app would not be created
  # because the "deleted" spec/dummy would still have it's "Dummy" rails app 
  # name in the Ruby VM environment.
  #
  system({"DISABLE_MIGRATE" => "true", 
          "DISABLE_CREATE" => "true"}, "rake dummy:app")
  
  # Bring in the customized mysql/postgres testing database.yml.
  database_path = "spec/dummy/config/database.yml"
  File.delete(database_path) if File.exists?(database_path)
  FileUtils.cp("spec/support/database.txt", database_path)
  
  Rake::Task["install_engine"].invoke
end

task :install_engine do 
  # Use system so that we load the dummy app's Rake commands.

  # Drop any existing db so that it is recreated; Hide output so there's no stack trace if the db doesn't exist
  system('cd spec/dummy && rake db:drop >/dev/null 2>&1')
  
  # Use system so that we funcitonally test the install generator.
  system("cd spec/dummy && rake db:create && rake db:migrate && rake db:test:prepare")
end
