require 'aasm'

# a visitor applies to a sleeve (application)
class Fe::Application < Fe::AnswerSheet
  self.table_name = "#{Fe.table_name_prefix}applications"
  include AASM
  
  COST = 35
  
  aasm :initial => :started, :column => :status do
  
    # State machine stuff
    state :started
    state :submitted, :enter => Proc.new {|app|
                                  Rails.logger.info("application #{app.id} submitted")
                                  app.notify_app_submitted
                                  app.submitted_at = Time.now
                                }

    state :completed, :enter => Proc.new {|app|
                                  Rails.logger.info("application #{app.id} completed")
                                  app.notify_app_completed
                                }

    state :unsubmitted, :enter => Proc.new {|app|
                                  # TODO: Do we need to send a notification here?
                                }

    state :withdrawn, :enter => Proc.new {|app|
                                  Rails.logger.info("application #{app.id} withdrawn")
                                  # TODO: Do we need to send a notification here?
                                  app.withdrawn_at = Time.now
                                }

    state :accepted, :enter => Proc.new {|app|
                                  Rails.logger.info("application #{app.id} accepted")
                                  app.accepted_at = Time.now
                               }

    state :declined, :enter => Proc.new {|app|
                                  Rails.logger.info("application #{app.id} declined")
                               }

    event :submit do
      transitions :to => :submitted, :from => :started
      transitions :to => :submitted, :from => :unsubmitted
      transitions :to => :submitted, :from => :withdrawn
      # Handle when user clicks to edit references, then clicks submit
      transitions :to => :submitted, :from => :submitted
    end

    event :withdraw do
      transitions :to => :withdrawn, :from => :started
      transitions :to => :withdrawn, :from => :submitted
      transitions :to => :withdrawn, :from => :completed
      transitions :to => :withdrawn, :from => :unsubmitted
      transitions :to => :withdrawn, :from => :declined
      transitions :to => :withdrawn, :from => :accepted
    end

    event :unsubmit do
      transitions :to => :unsubmitted, :from => :submitted
      transitions :to => :unsubmitted, :from => :withdrawn
    end

    event :complete do
      transitions :to => :completed, :from => :submitted
      transitions :to => :completed, :from => :unsubmitted
      transitions :to => :completed, :from => :started
      transitions :to => :completed, :from => :withdrawn
      transitions :to => :completed, :from => :declined
      transitions :to => :completed, :from => :accepted
    end

    event :accept do
      transitions :to => :accepted, :from => :completed
      transitions :to => :accepted, :from => :started
      transitions :to => :accepted, :from => :withdrawn
      transitions :to => :accepted, :from => :declined
      transitions :to => :accepted, :from => :submitted
    end

    event :decline do
      transitions :to => :declined, :from => :completed
      transitions :to => :declined, :from => :accepted
    end
  end

  belongs_to :applicant, :class_name => "Person", :foreign_key => "applicant_id"
  has_many :references, :class_name => 'ReferenceSheet', :foreign_key => :applicant_answer_sheet_id, :dependent => :destroy
  has_many :payments
  has_one :answer_sheet_question_sheet, :foreign_key => "answer_sheet_id"
  
  before_create :create_answer_sheet_question_sheet
  after_save :complete
  
  # The statuses that mean an application has NOT been submitted
  def self.unsubmitted_statuses
    %w(started unsubmitted)
  end

  # The statuses that mean an applicant is NOT ready to evaluate
  def self.not_ready_statuses
    %w(submitted)
  end

  # The statuses that mean an applicant is NOT going
  def self.not_going_statuses
    %w(withdrawn declined)
  end

  # The statuses that mean an applicant IS ready to evaluate
  def self.ready_statuses
    %w(completed)
  end

  # The statuses that mean an applicant's application is not completed, but still in progress
  def self.uncompleted_statuses
    %w(started submitted unsubmitted)
  end
  
  def self.post_ready_statuses
    %w(accepted affiliate alumni being_evaluated on_assignment placed re_applied terminated transfer pre_a follow_through)
  end
  
  def self.completed_statuses
    Apply.ready_statuses | Apply.post_ready_statuses | %w(declined)
  end

  def self.post_submitted_statuses
    Apply.completed_statuses | Apply.not_ready_statuses
  end
  
  def self.statuses
    Apply.unsubmitted_statuses | Apply.not_ready_statuses | Apply.ready_statuses | Apply.post_ready_statuses | Apply.not_going_statuses
  end
  
  def name
    applicant.try(:informal_full_name)
  end
  
  def email
    applicant.try(:email)
  end

  def phone
    applicant.try(:phone)
  end

  def has_paid?
    self.payments.each do |payment|
      return true if payment.approved?
    end
    return false
  end

  def paid_at
    self.payments.each do |payment|
      return payment.updated_at if payment.approved?
    end
    return nil
  end
  
  def payment_status
    self.has_paid? ? "Approved" : "Not Paid"
  end
  
  def completed_references
    sr = Array.new()
    references.each do |r|
      sr << r if r.completed?
    end
    sr
  end
  
  def staff_reference
    get_reference(Fe::Element.where("kind = 'Fe::ReferenceQuestion' AND style = 'staff'").first.id)
  end
  
  def discipler_reference
    get_reference(Fe::Element.where("kind = 'Fe::ReferenceQuestion' AND style = 'discipler'").first.id)
  end
  
  def roommate_reference
    get_reference(Fe::Element.where("kind = 'Fe::ReferenceQuestion' AND style = 'roommate'").first.id)
  end

  def friend_reference
    get_reference(Fe::Element.where("kind = 'Fe::ReferenceQuestion' AND style = 'friend'").first.id)
  end
  
  def get_reference(question_id)
    reference_sheets.each do |r|
      return r if r.question_id == question_id
    end
    return Fe::ReferenceSheet.new()
  end
  
  def answer_sheets
    a_sheets = [self]
    references.each do |r|
      a_sheets << r
    end
    a_sheets
  end
  
  def reference_answer_sheets
    r_sheets = Array.new()
    references.each do |r|
      r_sheets << r
    end
    r_sheets
  end
  
  def has_references?
    self.references.size > 0
  end
  
  def create_answer_sheet_question_sheet
    self.answer_sheet_question_sheet ||= ::Fe::AnswerSheetQuestionSheet.create(:question_sheet_id => 1) #TODO: NO CONSTANT
  end
  
  # The :frozen? method lets the QuestionnaireEngine know to not allow
  # the user to change the answer to a question.
  def frozen?
    !%w(started unsubmitted).include?(self.status)
  end

  def can_change_references?
    %w(started unsubmitted submitted).include?(self.status)
  end
  
  def notify_app_submitted
    Notifier.notification(self.email,
                          "stintandinternships@cru.org", 
                          "Application Submitted", 
                          {'applicant_first_name' => applicant.nickname, }).deliver
  end

  def notify_app_completed
    Notifier.notification(self.email,
                          "stintandinternships@cru.org", 
                          "Application Completed", 
                          {'applicant_first_name' => applicant.nickname, }).deliver
  end

  def complete(ref = nil)
    return true if self.completed?
    return false unless self.submitted?
    return false unless self.has_paid?
    references.each do |reference|
      return false  unless reference.completed? || reference == ref
    end
    return self.complete!
  end

end
