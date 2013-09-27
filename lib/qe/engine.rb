module Qe
  class Engine < ::Rails::Engine
    config.to_prepare do
      Dir.glob(File.join(File.dirname(__FILE__), "..", "..", "app", "**", "*_concern.rb")).each do |c|
        require_dependency(c)
      end
    end
  end
end
