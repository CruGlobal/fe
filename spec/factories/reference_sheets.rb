FactoryBot.define do
  factory :reference_sheet, class: Fe::ReferenceSheet do
    sequence(:email) { |n| "email_#{n}@email.com" }
    sequence(:first_name) { |n| "fn_#{n}" }
    sequence(:last_name) { |n| "ln_#{n}" }
    sequence(:phone) { |n| "phone_#{n}" }
    sequence(:relationship) { |n| "relationship_#{n}" }
  end
end
