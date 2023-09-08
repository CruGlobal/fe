# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :fe_phone_number, class: Fe::PhoneNumber do
    sequence(:number) { |n| "#{n}" * 6 }
  end
end
