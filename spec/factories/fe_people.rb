# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fe_person, :class => 'Fe::Person' do
    first_name "MyString"
    last_name "MyString"
  end
end
