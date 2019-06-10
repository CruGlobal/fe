# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :fe_email_template, :class => Fe::EmailTemplate do
    sequence(:content) { |n| "content_#{n}" }
    sequence(:subject) { |n| "subject#{n}" }
    enabled { true }
  end
end
