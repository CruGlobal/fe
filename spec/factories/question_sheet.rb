FactoryBot.define do
  factory :question_sheet, class: Fe::QuestionSheet do
    sequence(:label) { |n| "Question Sheet #{n}"}

    factory :question_sheet_with_pages do
      transient do
        pages_count { 5 }
      end

      after(:create) do |question_sheet, evaluator|
        create_list(:page, evaluator.pages_count, question_sheet: question_sheet)
      end
    end
  end
end
