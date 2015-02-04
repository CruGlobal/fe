FactoryGirl.define do
  factory :element, class: Fe::Element do
    sequence    :label do |n| "Label Element #{n}" end
    required    true
    sequence    :slug do |n| "element_#{n}" end

    factory :choice_field_element, class: Fe::ChoiceField do
      kind    "Fe::ChoiceField"
      style   "yes-no"
      content "Choice One\r\nChoice Two\r\nChoice Three"
    end

    factory :text_field_element, class: Fe::TextField do
      kind   "Fe::TextField"
      style  "short"
    end
  end
end
