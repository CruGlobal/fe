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

require 'rails/dummy/tasks'
