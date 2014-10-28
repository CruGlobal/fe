FactoryGirl.define do
  factory :payment, class: 'Fe::Payment' do
    association :application
    payment_type 'String'
    amount 1
  end
end
