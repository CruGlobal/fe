require 'aasm'
module Fe
  class ReferenceSheet < ActiveRecord::Base
    include Fe::AnswerSheetConcern
    include Rails.application.routes.url_helpers
    include AASM
    self.table_name = "#{Fe.table_name_prefix}references"
    self.inheritance_column = 'fake'

    belongs_to :question,
               :class_name => 'Element',
               :foreign_key => 'question_id'

    belongs_to :applicant_answer_sheet,
               :class_name => Fe.answer_sheet_class,
               :foreign_key => "applicant_answer_sheet_id"

    validates_presence_of :first_name, :last_name, :phone, :email, :relationship, :on => :update, :message => "can't be blank"

    delegate :style, :to => :question

    before_save :check_email_change

    after_destroy :notify_reference_of_deletion

    aasm :initial => :created, :column => :status do

      state :started, :enter => Proc.new {|ref|
        ref.started_at = Time.now
      }
      state :created
      state :completed, :enter => Proc.new {|ref|
        ref.submitted_at = Time.now
        # SpReferenceMailer.deliver_completed(ref)
        # SpReferenceMailer.deliver_completed_confirmation(ref)
        ref.applicant_answer_sheet.complete(ref)
      }

      event :start do
        transitions :to => :started, :from => :created
      end

      event :submit do
        transitions :to => :completed, :from => :started
        transitions :to => :completed, :from => :created
      end

      event :unsubmit do
        transitions :to => :started, :from => :completed
      end
    end

    alias_method :applicant, :applicant_answer_sheet
    def generate_access_key
      self.access_key = Digest::MD5.hexdigest(email + Time.now.to_s)
    end

    def frozen?
      !%w(started created).include?(self.status)
    end

    def email_sent?() !self.email_sent_at.nil? end

    # send email invite
    def send_invite
      return if self.email.blank?

      application = self.applicant_answer_sheet

      Notifier.notification(self.email,
                            application.email,
                            "Reference Invite",
                            {'reference_full_name' => self.name,
                             'applicant_full_name' => application.name,
                             'applicant_email' => application.email,
                             'applicant_home_phone' => application.phone,
                             'reference_url' => edit_reference_sheet_url(self, :a => self.access_key, :host => ActionMailer::Base.default_url_options[:host])}).deliver
      # Send notification to applicant
      Notifier.notification(applicant_answer_sheet.email, # RECIPIENTS
                            Fe.from_email, # FROM
                            "Reference Notification to Applicant", # LIQUID TEMPLATE NAME
                            {'applicant_full_name' => applicant_answer_sheet.name,
                             'reference_full_name' => self.name,
                             'reference_email' => self.email,
                             'application_url' => edit_answer_sheet_url(applicant_answer_sheet, :host => ActionMailer::Base.default_url_options[:host])}).deliver

      self.email_sent_at = Time.now
      self.save(:validate => false)

      true
    end

    def name
      [first_name, last_name].join(' ')
    end

    def reference
      self
    end

    def to_s
      name
    end

    def required?
      question.required?(applicant_answer_sheet)
    end

    def reference?
      true
    end

    # Can't rely on answer_sheet's implementation for old reference's that might have id's that may match an application id
    def question_sheet
      QuestionSheet.find(question.related_question_sheet_id) if question && question.related_question_sheet_id
    end

    # Can't rely on answer_sheet's implementation for old reference's that might have id's that may match an application id
    def question_sheets
      [question_sheet]
    end

    def display_type
      question.label.split(/:| \(/).first
    end

    protected
    # if the email address has changed, we have to trash the old reference answers
    def check_email_change
      if changed.include?('email')
        answers.destroy_all
        # Every time the email address changes, generate a new access_key
        generate_access_key
        self.email_sent_at = nil
        self.status = 'created'
      end
    end

    def notify_reference_of_deletion
      if email.present?
        Notifier.notification(email,
                              Fe.from_email,
                              "Reference Deleted",
                              {'reference_full_name' => self.name,
                               'applicant_full_name' => applicant_answer_sheet.name}).deliver
      end
    end
  end
end