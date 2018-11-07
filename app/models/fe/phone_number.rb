class Fe::PhoneNumber < ApplicationRecord
  belongs_to :person

  self.table_name = "phone_numbers"
end
