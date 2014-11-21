require 'bundler/setup'
require 'thor'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake' if File.exists? 'spec/dummy/Rakefile'

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task" 
RSpec::Core::RakeTask.new(:spec) do |spec|
  unless File.directory?("spec/dummy")
    Rake::Task['setup_dummy_app'].invoke unless ENV['SKIP_DUMMY_APP']
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
  
  # This is a hack to fix the require statement in application.rb
  # Rails uses the enclosing folder name 'qe' to determine what to include
  # Since the gem is still called qe travis created a qe folder
  app_contents = File.read("spec/dummy/config/application.rb")
  app_contents.gsub!('require "qe"', 'require "fe"')
  File.open("spec/dummy/config/application.rb", "w") do |f|
    f.write app_contents
  end

  # Bring in the customized mysql/postgres testing database.yml.
  database_path = "spec/dummy/config/database.yml"
  File.delete(database_path) if File.exists?(database_path)
  FileUtils.cp("spec/support/database.txt", database_path)
  
  Rake::Task["install_engine"].invoke
end

task :install_engine do 
  ENV['ENGINE'] = 'fe_engine'
  Rake::Task['dummy:install_migrations'].invoke

  # Use system so that we load the dummy app's Rake commands.

  # Drop any existing db so that it is recreated; Hide output so there's no stack trace if the db doesn't exist
  system('cd spec/dummy && RAILS_ENV=test rake db:drop >/dev/null 2>&1')
  
  # Use system so that we funcitonally test the install generator.
  system("cd spec/dummy && RAILS_ENV=test rake db:create && RAILS_ENV=test rake db:migrate")
end
