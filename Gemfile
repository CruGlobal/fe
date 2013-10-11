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
  platforms :jruby do
    gem 'activerecord-jdbcmysql-adapter'
    gem 'activerecord-jdbcpostgresql-adapter'
    gem 'jruby-openssl'
  end

  platforms :mri do
    gem 'mysql2'
    gem 'pg'
  end
end

gem 'database_cleaner', 
  "~> 1.1.1", 
  :git => 'https://github.com/tommeier/database_cleaner', 
  :ref => 'b0c666e'
