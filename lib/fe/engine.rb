require 'acts_as_list'

module Fe
  class Engine < ::Rails::Engine
    # isolate_namespace is causing problems accessing the app's url helpers when the app
    # mixes in methods to a controller.
    #
    # Using the si as an example:
    #
    # si/app/controllers/fe/test_controller.rb
    #
    #   class Fe::TestController < ApplicationController
    #     def index
    #     end
    #   end
    #
    # si/app/views/fe/test/index.html.erb
    #
    #   <%= logout_path %> <-- this will crash, no url helpers are accessible
    #
    # As explained here,
    # http://crypt.codemancers.com/posts/2013-09-22-isolate-namespace-in-rails-engines/
    # it's a real pain to extend an isolated namespace engine from the app:
    #
    #   "Other issues include extending models and controllers. Rails
    #   guides gives two options here. One to use class_eval, and other
    #   to use concerns introduced in Rails 4. Both are kind of hacky.
    #   Hope there is a better solution."
    #
    # and as per a user comment on that page:
    #
    #   "I've had a similar experience with `isolate_namespace`, if the engines
    #   need to be truely isolated it works, but if you need to extend the engine
    #   from the client app its best to remove it and just namespace manually.
    #
    # I'm disabling the isolate_namespace
    #
    #isolate_namespace Fe


    config.to_prepare do
      require_dependency('distinct_distinct_patch.rb')
      require_dependency('access_key_generator')

      # Loading concerns and dependencies here when running FE specs breaks the coverage report.  The
      # Rakefile will set SKIP_CONCERNS and SKIP_DECORATORS true and decorators/concerns are loaded from
      # spec/rails_helper.rb instead
      if ENV['SKIP_CONCERNS'] != 'true'
        Dir.glob(File.join(File.dirname(__FILE__), "..", "..", "app", "**", "*_concern.rb")).each do |c|
          require_dependency(c)
        end
      end

      if ENV['SKIP_CONCERNS'] != 'true'
        Dir.glob(File.join(Rails.root + 'app/decorators/**/*_decorator.rb')).each do |c|
          require_dependency(c)
        end
      end
    end

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    initializer "fe.asset_precompile_paths" do |app|
      app.config.assets.precompile += %w(fe/admin.js fe/fe.screen.css)
    end

    initializer "model_core.factories", :after => "factory_girl.set_factory_paths" do
      FactoryBot.definition_file_paths << File.expand_path('../../../spec/factories', __FILE__) if defined?(FactoryBot)
    end
  end
end
