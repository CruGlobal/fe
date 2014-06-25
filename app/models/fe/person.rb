class Fe::Person < ActiveRecord::Base
  belongs_to :user
  has_one    :current_address, -> { where("address_type = 'current'") }, :class_name => "Fe::Address"
  has_many   :email_addresses, :foreign_key => "person_id", :class_name => '::EmailAddress', dependent: :destroy
  has_many   :phone_numbers, :foreign_key => "person_id", :class_name => '::PhoneNumber', dependent: :destroy
  has_one    :current_address, -> { where("address_type = 'current'") }, :foreign_key => "person_id", :class_name => '::Fe::Address'
  has_one    :permanent_address, -> { where("address_type = 'permanent'") }, :foreign_key => "person_id", :class_name => '::Fe::Address'
  has_one    :emergency_address1, -> { where("address_type = 'emergency1'") }, :foreign_key => "person_id", :class_name => 'Fe::Address'
  has_many   :addresses, :foreign_key => "person_id", dependent: :destroy
  has_one    :fe_application, :foreign_key => "person_id", :class_name => "::Fe::Application"

  def emergency_address
    emergency_address1
  end
  def emergency_address=(address)
    self.emergency_address1 = address
  end

  def create_emergency_address
    Address.create(:person_id => self.id, :address_type => 'emergency1')
  end

  def create_current_address
    Address.create(:person_id => self.id, :address_type => 'current')
  end

  def create_permanent_address
    Address.create(:person_id => self.id, :address_type => 'permanent')
  end

end