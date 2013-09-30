module Qe
  class TextField < Question
    
    module M
      extend ActiveSupport::Concern    

      # which view to render this element?
      def ptemplate
        if self.style == 'qe/essay'
          'qe/text_area_field'
        else
          'qe/text_field' 
        end
      end
      
      # css class names for javascript-based validation
      def validation_class(answer_sheet)
        validation = ''
        validation += ' required' if self.required?(answer_sheet)
        # validate-number, etc.
        validate_style = ['number', 'currency-dollar', 'email', 'url', 'phone'].find {|v| v == self.style }
        if validate_style
          validation += ' validate-' + validate_style
        end
        validation
      end
    end

    include M
  end
end
