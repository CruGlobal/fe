FactoryBot.define do

  factory :page, class: Fe::Page do
    sequence :label do |n| "Label Page #{n}" end
    sequence :number do |n| n end
    association :question_sheet
  end
end

