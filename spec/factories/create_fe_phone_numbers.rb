# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :create_fe_phone_number, :class => 'CreateFePhoneNumbers' do
    number "MyString"
    extensions "MyString"
    person_id 1
    location "MyString"
    primary false
    txt_to_email "MyString"
    carrier_id 1
    email_updated_at "2014-06-24 14:22:16"
  end
end
