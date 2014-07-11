module Fe
  class PaymentQuestion < Question

    def response(answer_sheet=nil)
      return Payment.new unless answer_sheet
      answer_sheet.payments || [Payment.new(:answer_sheetlication_id => answer_sheet.id) ]
    end

    def display_response(answer_sheet=nil)
      response(answer_sheet).to_s
    end

    def has_response?(answer_sheet = nil)
      if answer_sheet
        answer_sheet.payments.length > 0
      else
        false
      end
    end

  end
end
