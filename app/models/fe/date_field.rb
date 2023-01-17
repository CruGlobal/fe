# DateField
# - a question that provides a calendar/date picker
module Fe
  class DateField < Question

    def validation_class(answer_sheet = nil, page = nil)
      if self.style == 'mmyy'
        'validate-selection ' + super
      else
        'validate-date ' + super
      end
    end

    def response(answer_sheet = nil)
      r = super
      return nil if r.blank?
      begin
        if r.is_a?(String)
          parts = r.split('/')
          if parts.length == 3
            r = Time.mktime(parts[2], parts[0], parts[1])
          else
            r = Time.parse(r)
          end
        end
      rescue ArgumentError
        r = ''
      end
      r
    end

    def display_response(answer_sheet = nil)
      return format_date_response(answer_sheet)
    end

    def format_date_response(answer_sheet = nil)
      r = response(answer_sheet)
      r = r.strftime("%Y-%m-%d") unless r.blank?
      r
    end

    # which view to render this element?
    def ptemplate
      if self.style == 'mmyy'
        'fe/date_field_mmyy'
      else
        'fe/date_field'
      end
    end

  end
end
