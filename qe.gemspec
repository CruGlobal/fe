$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "qe/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "qe"
  s.version     = Qe::VERSION
  s.authors     = ["CruGlobal"]
  s.email       = ["programmers@cojourners.com"]
  s.homepage    = "http://cru.org"
  s.summary     = "Questionnaire Engine"
  s.description = "A rails engine that facilitates question/answer stuff"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.1.0"
  s.add_dependency "ckeditor", "3.7.1"
  s.add_dependency "jquery-rails"
  s.add_dependency "jquery-ui-rails"
  
  s.add_development_dependency 'mysql2', '~> 0.3.11'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'rails-dummy'
  
  # https://github.com/bmabey/database_cleaner/issues/224
  # https://github.com/bmabey/database_cleaner/pull/241
  # therefore added custom branch to Gemfile
  # 
  # s.add_development_dependency 'database_cleaner', '1.0.1'
end
