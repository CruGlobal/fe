## Fe

[![Build Status](https://travis-ci.org/CruGloabl/fe.png?branch=master)](https://travis-ci.org/CruGloabal/fe)

This project rocks and uses MIT-LICENSE.

### Development

### Testing

Setup the testing db

    bundle exec rake setup_db

Run specs:
    
    bundle exec rake spec
    
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
