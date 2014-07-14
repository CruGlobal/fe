class Staff < ActiveRecord::Base
  self.table_name = "ministry_staff"
  belongs_to :person
  
  belongs_to :primary_address, :class_name => "StaffAddress", :foreign_key => :fk_primaryAddress
  belongs_to :secondary_address, :class_name => "StaffAddress", :foreign_key => :fk_secondaryAddress
  
  def self.get_staff(ssm_id)
    if ssm_id.nil? then raise "nil ssm_id!" end
    ssm_user = User.find_by(userID: ssm_id)
    if ssm_user.nil? then raise "ssm_id doesn't exist: #{ssm_id}" end
    username = ssm_user.username
    profile = StaffsiteProfile.find_by(userName: username)
    account_no = profile.accountNo
    staff = Staff.find_by(accountNo: account_no)
  end
  
  def self.field_roles
    @@field_roles ||= ['Director (Direct Ministry)','Team Leader (Direct Ministry)','Team Member - Mom','Field Staff In Training','Raising Support Full Time','Seminary Staff','Field Staff','Local Leader']
  end
  
  def self.strategy_order
    @@strategy_order ||= ['National Director','Operations','HR','LD','Fund Dev','CFM','FLD','EFM','DES','EPI','ESS','NTN','BRD','WSN','GLM','R&D','SR','SV','SSS','JPO','LHS','']
  end
  
  def self.strategies
    @@strategies ||= {
      'National Director' => 'National Director',
      'Operations' => 'Operations',
      'HR' => 'Leadership Development',
      'LD' => 'Leadership Development',
      'Fund Dev' => 'Fund Development',
      'CFM' => 'Campus Field Ministry',
      'FLD' => 'Campus Field Ministry',
      'SV' =>  'Cru High School',
      'EFM' => 'Ethnic Field Ministry',
      'DES' => 'Destino',
      'EPI' => 'Epic',
      'ESS' => 'Every Student Sent',
      'NTN' => 'Nations',
      'BRD' => 'Bridges',
      'WSN' => 'Global Missions',
      'GLM' => 'Global Missions',
      'R&D' => 'Research and Development',
      'LHS' => 'Lake Hart Stint'
    }
  end
  
  def self.staff_positions
    @@staff_positions ||= [
      "Associate Staff",
      "Staff Full Time",
      "Hourly Full Time",
      "Hourly on Call",
      "Salaried Exempt Full Time",
      "Salaried w Desig #",
      "Self-Supported Staff",
      "Staff on Delayed Payroll",
      "Staff on Paid Leave",
      "Staff on Unpaid Leave",
      "Staff Raising Init Supprt",
      "Affiliate",
      "Volunteer Full Time",
      "Volunteer Part Time",
      "Ministry Intern A",
      "Ministry Intern A Part Time",
      "Ministry Intern Hourly Part Tm",
      "STINT Full Time",
      "Staff Part Time"
    ]
  end
  
  scope :specialty_roles, -> { where(:jobStatus => "Staff Full Time").where(:ministry => "Campus Ministry").
      where(:removedFromPeopleSoft => "N").where("jobTitle NOT IN (?)", field_roles).order(:jobTitle).order(:lastName) }

  def self.get_roles(region)
    result = {}
    Staff.strategy_order.each do |strategy|
      result[strategy] = specialty_roles.where(:strategy => strategy).where(:region => region)
    end
    result
  end

  def email
    self[:email].present? ? self[:email] : self.person.try(:email)
  end

  # "first_name last_name"
  def full_name
    firstName.to_s  + " " + lastName.to_s
  end

  def informal_full_name
    nickname.to_s  + " " + lastName.to_s
  end
  
  def nickname
    (!preferredName.to_s.strip.empty?) ? preferredName : firstName
  end
  
  def is_active?
    removedFromPeopleSoft != "Y"
  end
  
  def is_hr?
    strategy == "HR" || strategy == "LD"
  end
  
  def is_director?
    jobTitle && jobTitle.include?("Director")
  end

  def is_hr_director?
    jobTitle && jobTitle.include?("Director (HR)")
  end
  
  def is_removed?
    removedFromPeopleSoft == "Y" ? true : false
  end
end
