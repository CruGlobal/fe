module Fe
  class Engine < ::Rails::Engine
    isolate_namespace Fe

    config.to_prepare do
      Dir.glob(File.join(File.dirname(__FILE__), "..", "..", "app", "**", "*_concern.rb")).each do |c|
        require_dependency(c)
      end
    end

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

  end
end
