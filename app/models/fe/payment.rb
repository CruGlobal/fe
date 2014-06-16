module Fe
  class Payment < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    attr_accessor :first_name, :last_name, :address, :city, :state, :zip, :card_number, :payment_type,
                  :expiration_month, :expiration_year, :security_code, :staff_first, :staff_last, :card_type

    scope :non_denied, -> { where("(status <> 'Denied' AND status <> 'Errored') OR status is null") }

    belongs_to :answer_sheet, class_name: Fe.answer_sheet_class

    after_save :check_answer_sheet_complete

    def validate
      if credit?
        errors.add_on_empty([:first_name, :last_name, :address, :city, :state, :zip, :card_number,
                             :expiration_month, :expiration_year, :security_code])
        errors.add(:card_number, "is invalid.") if get_card_type.nil?
      end
    end

    def check_answer_sheet_complete
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
      self.save!
    end

    def get_card_type
      card =  ActiveMerchant::Billing::CreditCard.new(:number => card_number)
      card.valid?
      card.type
    end
  end

end
