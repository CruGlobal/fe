source "https://rubygems.org"

gemspec

### ensure these gems are present in spec/dummy
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'dynamic_form'
gem 'aasm'
###

### TravisCI db drivers
group :development, :test do
  platforms :mri do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
  gem 'spork-rails'#, '~> 3.2.0'
  gem 'rb-fsevent', :require => false
  gem 'guard-spork'
  gem 'guard-rspec', require: false
  gem 'simplecov', :require => false
end

gem 'database_cleaner', 
  "~> 1.1.1", 
  :git => 'https://github.com/tommeier/database_cleaner', 
  :ref => 'b0c666e'
