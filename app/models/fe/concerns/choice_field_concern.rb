require 'net/http'
# :nocov:
begin
  require 'xml/libxml'
rescue LoadError
  require 'rexml/document'
end
# :nocov:

module Fe
  module ChoiceFieldConcern
    extend ActiveSupport::Concern

    begin
      included do
        has_many :elements, :class_name => "Element", :foreign_key => "choice_field_id", :dependent => :nullify#, :order => :position
      end
    rescue ActiveSupport::Concern::MultipleIncludedBlocks
    end

    # Returns choices stored one per line in content field
    def choices(locale = nil)
      retVal = Array.new
      if ['yes-no', 'acceptance'].include?(self.style)
        return [[_('Yes'),1],[_('No'),0]]
      elsif source.present?
        begin
          doc = XML::Document.file(source)
          options = doc.find(text_xpath).collect { |n| n.content }
          values = doc.find(value_xpath).collect { |n| n.content }
          retVal = [options, values].transpose
        rescue NameError, LibXML::XML::Error
          doc = REXML::Document.new Net::HTTP.get_response(URI.parse(source)).body
          retVal = [ doc.elements.collect(text_xpath){|c|c.text}, doc.elements.collect(value_xpath){|c|c.text} ].transpose
        end
      elsif content.present?
        choices = content(locale)
        choices.split("\n").each do |opt|
          pair = opt.strip.split(";").reverse!
          pair[1] ||= pair[0]
          retVal << pair
        end
      end
      return retVal
    end

    def has_answer?(choice, app)
      responses(app).each do |r|   # loop through Answers
                                   # legacy field type choices may be int or tinyint
                                   # raise r.inspect + ' - ' + choice.inspect if id == 1137 && r != 1
                                   # r = r.to_s
        return true if  case true
                          when is_true(r) then is_true(choice)
                          when is_false(r) then is_false(choice)
                          else
                            r.to_s == choice.to_s
                        end
      end
      false
    end

    # which view to render this element?
    def ptemplate
      # TODO case would be nicer
      if self.style == 'checkbox'
        'fe/checkbox_field'
      elsif self.style == 'drop-down'
        'fe/drop_down_field'
      elsif self.style == 'radio'
        'fe/radio_button_field'
      elsif self.style == 'yes-no'
        'fe/yes_no'
      elsif self.style == 'rating'
        'fe/rating'
      elsif self.style == 'acceptance'
        'fe/acceptance'
      elsif self.style == 'country'
        'fe/country'
      end
    end

    # element view provides the element label?
    def default_label?
      if self.style == 'acceptance' || self.hide_option_labels?
        false   # template provides its own label
      else
        true
      end
    end

    # css class names for javascript-based validation
    def validation_class(answer_sheet)
      if self.required?(answer_sheet)
        if self.style == 'drop-down'
          'validate-selection required'
        elsif self.style == 'rating'
          'validate-rating required'
        elsif self.style == 'acceptance'
          'required'
        else
          'validate-one-required required'
        end
      else
        ''
      end
    end

    def display_response(app = nil, joiner = ', ')
      r = responses(app)
      r.reject! {|a| a.class == Answer && a.value.blank?}
      if r.blank?
        ""
      elsif self.style == 'yes-no'
        ans = r.first
        if ans.class == Answer
          is_true(ans.value) ? "Yes" : "No"
        else
          is_true(ans) ? "Yes" : "No"
        end
      elsif self.style == 'acceptance'
        "Accepted"  # if not blank, it's accepted
      else
        r.compact.join(joiner)
      end
    end

    def conditional_match(answer_sheet)
      displayed_response = display_response(answer_sheet, ';')
      responses_arr = display_response(answer_sheet).split(';')
      (is_true(displayed_response) && is_true(conditional_answer)) ||
        (is_response_false(answer_sheet) && is_false(conditional_answer)) ||
        (responses_arr.empty? && conditional_answers.empty?) ||
        (responses_arr && conditional_answers).any?
    end

    def is_response_false(answer_sheet)
      is_false(display_response(answer_sheet))
    end

    protected
    def is_true(val)
      ['1','true','yes'].include?(val.to_s.downcase)
    end

    def is_false(val)
      # returns false if false (a bit odd)
      ['0','false','no'].include?(val.to_s.downcase)
    end

  end
end
