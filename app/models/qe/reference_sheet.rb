module Qe
  class ReferenceSheet < AnswerSheet
    # should be required within the concerns included module
    # include Rails.application.routes.url_helpers
    
    # include Qe::Concerns::Models::ReferenceSheet

    module M
      extend ActiveSupport::Concern
      
      included do    
        require 'state_machine'
        # NOTE -- since inheriting from AnswerSheet, you need to explicitly declare the table name,
        #         rather than it being implicitly inherited from the module/class.
        self.table_name = "#{Qe.table_name_prefix}reference_sheets"
        
        self.inheritance_column = 'fake'
        
        belongs_to :question, 
          :class_name => Qe::Element, 
          :foreign_key => 'question_id'
          
        belongs_to :applicant_answer_sheet, 
          :class_name => Qe::AnswerSheet, 
          :foreign_key => "applicant_answer_sheet_id"
        
        delegate :style, :to => :question
        before_save :check_email_change
        after_destroy :notify_reference_of_deletion
        
        attr_accessible :first_name, :last_name, :phone, :email, :relationship, 
          :applicant_answer_sheet_id, :question_id
        
        validates_presence_of :first_name, :last_name, :phone, :email, 
        :relationship, :on => :update, :message => "can't be blank"

        # state column is 'status'
        state_machine :status, :initial => :created do
          after_transition :on => :completed, :do => :prod_method
          
          event :start do
            transition :to => :started, :from => :created
          end
          
          event :submit do
            transition :to => :completed, :from => :started
          end

          event :unsubmit do
            transition :to => :started, :from => :completed
          end
        end
      end

      def proc_method

        # state :completed, :enter => Proc.new {|ref|
        #                               ref.submitted_at = Time.current
        #                               # SpReferenceMailer.deliver_completed(ref)
        #                               # SpReferenceMailer.deliver_completed_confirmation(ref)
        #                               ref.applicant_answer_sheet.complete(ref)
        #                             }

        submitted_at = Time.current
        # SpReferenceMailer.deliver_completed(ref)
        # SpReferenceMailer.deliver_completed_confirmation(ref)
        ref.applicant_answer_sheet.completed(ref)
        # done
      end

      # TODO check this out within the ActiveSupport::Concerns strategy
      # alias_method :applicant, :applicant_answer_sheet
      
      def generate_access_key
        self.access_key = Digest::MD5.hexdigest(email.to_s + Time.current.to_s)
      end
      
      def frozen?
        !%w(started).include?(self.status)
      end
      
      def email_sent?() !self.email_sent_at.nil? end
      
      # send email invite
      def send_invite    
        return if self.email.blank?
        
        application = self.applicant_answer_sheet
        
        Qe::Notifier.deliver_notification(self.email,
                                      application.email, 
                                      "Reference Invite", 
                                      {'reference_full_name' => self.name, 
                                       'applicant_full_name' => application.name,
                                       'applicant_email' => application.email, 
                                       'applicant_home_phone' => application.phone, 
                                       'reference_url' => edit_reference_sheet_url(self, :a => self.access_key, :host => ActionMailer::Base.default_url_options[:host])})
        # Send notification to applicant
        Qe::Notifier.deliver_notification(applicant_answer_sheet.email, # RECIPIENTS
                                      Qe.from_email, # FROM
                                      "Reference Notification to Applicant", # LIQUID TEMPLATE NAME
                                      {'applicant_full_name' => applicant_answer_sheet.name,
                                       'reference_full_name' => self.name,
                                       'reference_email' => self.email,
                                       'application_url' => edit_answer_sheet_url(applicant_answer_sheet, :host => ActionMailer::Base.default_url_options[:host])})

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
          Qe::Notifier.deliver_notification(email,
                                Qe.from_email, 
                                "Reference Deleted", 
                                {'reference_full_name' => self.name, 
                                 'applicant_full_name' => applicant_answer_sheet.name})
        end
      end

    end

    include M
  end
end
