class Fe::PhoneNumber < ActiveRecord::Base
  belongs_to :person

  self.table_name = "phone_numbers"
end
