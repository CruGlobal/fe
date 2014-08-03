class Fe::EmailAddress < ActiveRecord::Base
  belongs_to :person

  self.table_name = "email_addresses"
end
