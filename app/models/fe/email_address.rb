require 'validates_email_format_of'
class Fe::EmailAddress < ApplicationRecord
  belongs_to :person
  validates :email, :email_format => { :message => "doesn't look right." }

  self.table_name = "email_addresses"
end
