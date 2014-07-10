# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :application, :class => 'Fe::Application' do
    applicant_id 1
  end
end
