module Fe
  class Payment < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    attr_accessor :first_name, :last_name, :address, :city, :state, :zip, :card_number, :payment_type,
                  :expiration_month, :expiration_year, :security_code, :staff_first, :staff_last, :card_type

    belongs_to :application, class_name: Fe.answer_sheet_class

    scope :non_denied, -> { where("(status <> 'Denied' AND status <> 'Errored') OR status is null") }

    after_save :check_app_complete

    validate :credit_card_validation
    validate :staff_email_present_if_staff_payment

    def credit_card_validation
      if credit?
        errors.add_on_empty([:first_name, :last_name, :address, :city, :state, :zip, :card_number,
                             :expiration_month, :expiration_year, :security_code])
        errors.add(:card_number, "is invalid.") if get_card_type.nil?
      end
    end

    def staff_email_present_if_staff_payment
      if staff? && !payment_account_no.include?('/') # Don't try to validate chart fields
        staff = Staff.find_by(accountNo: payment_account_no)
        unless staff
          errors.add(:base, "We couldn't find a staff member with that account number")
          return false
        end

        unless staff.email.present?
          errors.add(:base, "The staff member you've picked doesn't have an address on file for us to send the request to.")
        end
      end
    end

    def to_s
      "#{payment_type}: #{amount} on #{created_at}"
    end

    def check_app_complete
      if self.approved?
        self.answer_sheet.complete
      end
    end

    def credit?
      self.payment_type == 'Credit Card'
    end

    def staff?
      self.payment_type == 'Staff'
    end

    def approved?
      self.status == 'Approved'
    end

    def approve!
      self.status = 'Approved'
      self.auth_code ||= card_number[-4..-1]
      self.save!
    end

    def get_card_type
      card =  ActiveMerchant::Billing::CreditCard.new(:number => card_number)
      card.valid?
      card.type
    end
  end

end
