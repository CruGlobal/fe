require 'bundler/setup'
require 'thor'

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake' if File.exists? 'spec/dummy/Rakefile'

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task" 
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = "-I #{File.expand_path('../spec/', __FILE__)}"
  spec.pattern = FileList[File.expand_path('../spec/**/*_spec.rb', __FILE__)]
end
task default: :spec

task :setup_db do
  # Use system so that we load the dummy app's Rake commands.

  # Drop any existing db so that it is recreated; Hide output so there's no stack trace if the db doesn't exist
  out = system('cd spec/dummy && RAILS_ENV=test bundle exec rake db:drop >/dev/null 2>&1')
  puts "Output of db:drop\n #{out}"
  
  # Use system so that we funcitonally test the install generator.
  out = system("cd spec/dummy && RAILS_ENV=test bundle exec rake db:create && RAILS_ENV=test bundle exec rake db:migrate")
  puts "Output of migrate:\n #{out}"
end

require 'rails/dummy/tasks'

task :skip_concerns do
  ENV['SKIP_CONCERNS'] = 'true'
end
task :skip_decorators do
  ENV['SKIP_DECORATORS'] = 'true'
end

task :spec => [ :skip_concerns, :skip_decorators ]


