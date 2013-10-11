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
  # spec.rspec_opts = ['-cfs --backtrace']
end
task default: :spec

ENV['DUMMY_PATH'] = 'spec/dummy'
# ENV['ENGINE']
# ENV['TEMPLATE']
require 'rails/dummy/tasks'
