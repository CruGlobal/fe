# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :fe_address, class: Fe::Address do
    address1 { "MyString" }
    address2 { "MyString" }
    address3 { "MyString" }
    address4 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    zip { "MyString" }
    country { "MyString" }
  end
end
