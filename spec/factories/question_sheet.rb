FactoryGirl.define do
  factory :question_sheet, class: Fe::QuestionSheet do
    sequence(:label) { |n| "Question Sheet #{n}"}
  end
end
