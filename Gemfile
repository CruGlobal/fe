source "https://rubygems.org"

gemspec

### ensure these gems are present in spec/dummy
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'dynamic_form'
gem 'aasm'
###

### rails4 attr_accessible compatibility
gem 'protected_attributes'

### TravisCI db drivers
group :development, :test do
  platforms :mri do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end

gem 'database_cleaner', 
  "~> 1.1.1", 
  :git => 'https://github.com/tommeier/database_cleaner', 
  :ref => 'b0c666e'
