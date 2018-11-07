FactoryBot.define do
  factory :email_template, :class => 'Fe::EmailTemplate' do
    name { "Staff Payment Request" }
  end
end
