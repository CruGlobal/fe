require 'validates_email_format_of'
require 'aasm'
module Fe
  class ReferenceSheet < ActiveRecord::Base
    include Fe::AnswerSheetConcern
    include Rails.application.routes.url_helpers
    include AASM
    include AccessKeyGenerator

    self.table_name = "#{Fe.table_name_prefix}references"
    self.inheritance_column = 'fake'

    belongs_to :question,
               :class_name => 'Fe::ReferenceQuestion',
               :foreign_key => 'question_id'

    belongs_to :applicant_answer_sheet,
               :class_name => "::#{Fe.answer_sheet_class}",
               :foreign_key => "applicant_answer_sheet_id"

    # using belongs_to :question_sheet doesn't work, it uses the Fe::AnswerSheetConcern#question_sheet implementation
    belongs_to :question_sheet_ref, class_name: 'Fe::QuestionSheet', foreign_key: :question_sheet_id

    validates_presence_of :first_name, :last_name, :phone, :email, :relationship, :on => :update, :message => "can't be blank"
    validates :email, :email_format => { :on => :update, :message => "doesn't look right." }

    delegate :style, :to => :question

    before_save :check_email_change
    before_create :set_question_sheet

    after_destroy :notify_reference_of_deletion

    aasm :column => :status do

      state :started, :enter => Proc.new {|ref|
        ref.started_at = Time.now
      }
      state :created, initial: true
      state :completed, :enter => Proc.new {|ref|
        ref.submitted_at = Time.now
        # SpReferenceMailer.deliver_completed(ref)
=begin
        Fe::Notifier.notification(ref.email, # RECIPIENTS
                                  Fe.from_email, # FROM
# TODO
                                  "Reference Completed", # LIQUID TEMPLATE NAME
                                  {'first_name' => person.nickname,
                                   'site_url' => "#{APP_CONFIG['spgive_url']}/#{person.sp_gcx_site}/",
                                   'username' => person.user.username,
                                   'password' => person.user.password_plain}).deliver
=end

        # SpReferenceMailer.deliver_completed_confirmation(ref)
=begin
        Fe::Notifier.notification(ref.applicant_answer_sheet.person.email, # RECIPIENTS
                                  Fe.from_email, # FROM
                                  "Reference Completed To Applicant", # LIQUID TEMPLATE NAME
# TODO
                                  {'first_name' => person.nickname,
                                   'site_url' => "#{APP_CONFIG['spgive_url']}/#{person.sp_gcx_site}/",
                                   'username' => person.user.username,
                                   'password' => person.user.password_plain}).deliver
=end

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

    alias_method :application, :applicant_answer_sheet
    delegate :applicant, to: :application

    def frozen?
      !%w(started created).include?(self.status)
    end

    def email_sent?() !self.email_sent_at.nil? end

    # send email invite
    def send_invite
      return if self.email.blank?

      application = self.applicant_answer_sheet

      Notifier.notification(self.email,
                            Fe.from_email,
                            "Reference Invite",
                            {'reference_full_name' => self.name,
                             'applicant_full_name' => application.applicant.name,
                             'applicant_email' => application.applicant.email,
                             'applicant_home_phone' => application.applicant.phone,
                             'reference_url' => edit_fe_reference_sheet_url(self, :a => self.access_key, :host => ActionMailer::Base.default_url_options[:host])}).deliver
      # Send notification to applicant
      Notifier.notification(applicant_answer_sheet.applicant.email, # RECIPIENTS
                            Fe.from_email, # FROM
                            "Reference Notification to Applicant", # LIQUID TEMPLATE NAME
                            {'applicant_full_name' => applicant_answer_sheet.applicant.name,
                             'reference_full_name' => self.name,
                             'reference_email' => self.email,
                             'application_url' => edit_fe_answer_sheet_url(applicant_answer_sheet, :host => ActionMailer::Base.default_url_options[:host])}).deliver

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
      question_sheet_ref
    end

    def question_sheets
      [question_sheet_ref]
    end

    def question_sheet_ids
      [question_sheet_id].compact
    end

    def display_type
      question.label.split(/:| \(/).first
    end

    def optional?
      question.try(:hidden?, applicant_answer_sheet)
    end

    def required?
      !optional?
    end

    protected
    
    def set_question_sheet
      self.question_sheet_id = question.try(:related_question_sheet_id)
    end

    # if the email address has changed, we have to trash the old reference answers
    def check_email_change
      if !new_record? && changed.include?('email')
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
