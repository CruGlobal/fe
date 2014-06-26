# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fe_apply, :class => 'Fe::Apply' do
    applicant_id 1
    status "MyString"
    submitted_at "2014-06-25 20:38:40"
  end
end
