## Qe

This project rocks and uses MIT-LICENSE.

### Development

### Testing
Setup a testing environment that mimics the Travis CI setup:

    cd qe
    bundle install
    DISABLE_MIGRATE=true DISABLE_CREATE=true rake dummy:app
    
    # bring a multi database.yml file
    rm spec/dummy/config/database.yml
    cp spec/support/database.txt spec/dummy/config/database.yml
    
    cd spec/dummy && rake db:create && cd ../..
    cd spec/dummy && rails g qe:install && rake db:test:prepare && cd ../..

    


