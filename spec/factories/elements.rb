FactoryBot.define do
  factory :element, class: Fe::Element do
    sequence    :label do |n| "Label Element #{n}" end
    required    { true }

    factory :choice_field_element, class: Fe::ChoiceField do
      kind    { "Fe::ChoiceField" }
      style   { "yes-no" }
      content { "Choice One\r\nChoice Two\r\nChoice Three" }
    end
    factory :date_field_element, class: Fe::DateField do
      kind    { "Fe::DateField" }
      style   { "date" }
    end
    factory :text_field_element, class: Fe::TextField do
      kind   { "Fe::TextField" }
      style  { "short" }
    end
    factory :question_grid, class: Fe::QuestionGrid do
      kind   { "Fe::QuestionGrid" }
      style  { "grid" }
    end
    factory :question_grid_with_total, class: Fe::QuestionGridWithTotal do
      kind   { "Fe::QuestionGridWithTotal" }
      style  { "grid" }
    end
    factory :reference_element, class: Fe::ReferenceQuestion do
      kind   { "Fe::ReferenceQuestion" }
      style  { "staff" }
    end
    factory :section, class: Fe::Section do
      kind   { "Fe::Section" }
      style  { "section" }
    end
    factory :attachment_field_element, class: Fe::AttachmentField do
      kind   { "Fe::AttachmentField" }
      style  { "section" }
    end
    factory :state_chooser_element, class: Fe::StateChooser do
      kind   { "Fe::StateChooser" }
      style  { "section" }
    end
  end
end
