# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fe_application, :class => 'Fe::Application' do
    person_id 1
  end
end
