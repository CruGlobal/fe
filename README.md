## Fe

[![Build Status](https://travis-ci.org/CruGloabl/fe.png?branch=master)](https://travis-ci.org/CruGloabal/fe)

This project rocks and uses MIT-LICENSE.

### Development

### Testing

Setup a testing environment that mimics the Travis CI setup:

    rake setup_dummy_app 

Run specs:
    
    rake spec
    
Run a specific spec:

    ruby -I$GEM_HOME/gems/rspec-core-3.0.2/lib:$GEM_HOME/gems/rspec-support-3.0.2/lib -S -I fe/spec rspec spec/models/fe/element_spec.rb

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
