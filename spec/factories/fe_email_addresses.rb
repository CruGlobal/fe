# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :fe_email_address, :class => Fe::EmailAddress do
    sequence(:email) { |n| "email_#{n}@email.com" }
  end
end
