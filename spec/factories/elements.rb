FactoryGirl.define do
  factory :element, class: Fe::Element do
    sequence    :label do |n| "Label Element #{n}" end
    required    true

    factory :choice_field_element, class: Fe::ChoiceField do
      kind    "Fe::ChoiceField"
      style   "yes-no"
      content "Choice One\r\nChoice Two\r\nChoice Three"
    end

    factory :text_field_element, class: Fe::TextField do
      kind   "Fe::TextField"
      style  "short"
    end
    factory :question_grid, class: Fe::QuestionGrid do
      kind   "Fe::QuestionGrid"
      style  "grid"
    end
    factory :reference_element, class: Fe::ReferenceQuestion do
      kind   "Fe::ReferenceQuestion"
      style  "staff"
    end
  end
end
