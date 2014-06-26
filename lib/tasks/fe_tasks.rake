# desc "Explaining what the task does"
# task :fe do
#   # Task goes here
# end

namespace :fe_engine do
  namespace :db do
    desc "Load seeds from fe_engine"
    task :seed => :environment do
      Fe::Engine.load_seed
    end
  end
end

