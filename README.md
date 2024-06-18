## Fe (Form Engine)

This project rocks and uses MIT-LICENSE.

Supports rails >= 5

### Development

### Testing

Note: The tests need ruby 2 to run, and is set up with rails 5.

Setup the testing db

    Configure spec/dummy/config/database.yml

    $ RAILS_ENV=test bundle exec rake app:db:environment:set db:create db:schema:load

Run specs:
    
    $ bundle exec rake spec
    
Run a specific spec:

    bundle exec rspec spec/models/fe/element_spec.rb

### Example enclosing app

    rails new 

## install devise

# add to gemfile

    gem 'devise'

# run

    bundle install
    rails generate devise:install
    rails generate devise User

# add to gemfile

    github: 'CruGlobal/qe', branch: 'fe'

# run

    bundle exec rake fe_engine:install:migrations

# add example user

    bundle exec rails console

    User.new({ :email => 'user@example.com', :password => 'password', :password_confirmation => 'password'}).save

# start server

    bundle exec rails server
