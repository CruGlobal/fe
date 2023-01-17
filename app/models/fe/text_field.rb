# TextField
# - a question that prompts for one or more lines of text

module Fe
  class TextField < Question

    # which view to render this element?
    def ptemplate
      if self.style == 'essay'
        'fe/text_area_field'
      else
        'fe/text_field'
      end
    end

    # css class names for javascript-based validation
    def validation_class(answer_sheet, page = nil)
      validation = ''
      validation += ' required' if self.required?(answer_sheet, page)
      # validate-number, etc.
      validate_style = ['number', 'currency-dollar', 'email', 'url', 'phone'].find {|v| v == self.style }
      if validate_style
        validation += ' validate-' + validate_style
      end
      validation
    end

  end
end
