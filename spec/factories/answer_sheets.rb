FactoryBot.define do
  factory :answer_sheet, class: Fe::Application do
    created_at { Time.now }
  end
end
