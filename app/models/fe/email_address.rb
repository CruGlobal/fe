class Fe::EmailAddress < ActiveRecord::Base
  belongs_to :person
  validates :email, :email_format => { :message => "doesn't look right." }

  self.table_name = "email_addresses"
end
