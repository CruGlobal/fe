source "https://rubygems.org"

gemspec

### ensure these gems are present in spec/dummy
gem 'rails', '~> 5.2'
gem 'acts_as_list', '>= 0.9.17'
gem 'aasm', '>= 4', '< 6'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'carmen', '~> 0.2.12'
gem 'validates_email_format_of'
gem 'liquid'
gem 'sass'
gem 'gettext_i18n_rails', '>= 1.2.3'
gem 'paper_trail', '>= 10'
gem 'libxml-ruby', '>= 5.0.3'
gem 'sassc-rails'
###

### For tests
group :development, :test do

  # choose which you want to use and comment the other out
  gem 'mysql2', '~> 0.5.2'
  gem 'pg', '~> 0.20'

  gem 'rb-fsevent', require: false
  gem 'guard-rspec', require: false
  gem 'simplecov', require: false
  gem 'rails-dummy'#, github: 'wafcio/rails-dummy', branch: 'rails41'
  gem 'rails-controller-testing'

  if RUBY_VERSION =~ /^2/
    gem 'rubysl-rexml'
  end

  # gem 'pry'
  # gem 'pry-remote'
  # gem 'pry-stack_explorer'
  # gem 'pry-byebug'
end

gem 'database_cleaner'
