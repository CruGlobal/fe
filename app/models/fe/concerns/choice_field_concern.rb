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
        serialize :rating_before_label_translations, Hash
        serialize :rating_after_label_translations, Hash
        serialize :rating_na_label_translations, Hash
      end
    rescue ActiveSupport::Concern::MultipleIncludedBlocks
    end

    def rating_before_label(locale = nil)
      rating_before_label_translations &&
        rating_before_label_translations[locale].present? ?
        rating_before_label_translations[locale] : self[:rating_before_label]
    end

    def rating_after_label(locale = nil)
      rating_after_label_translations && 
        rating_after_label_translations[locale].present? ?
        rating_after_label_translations[locale] : self[:rating_after_label]
    end

    def rating_na_label(locale = nil)
      rating_na_label_translations && 
        rating_na_label_translations[locale].present? ?
        rating_na_label_translations[locale] : self[:rating_na_label]
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

    # choices can be an array, in which case any match returns true
    def has_answer?(choice, answer_sheet)
      if choice.is_a?(Array)
        return choice.any? { |c| 
          has_answer?(c, answer_sheet)
        }
      end

      responses(answer_sheet).any? { |r|
        is_true(r) && is_true(choice) ||
        is_false(r) && is_false(choice) ||
        r.to_s.strip == choice.to_s.strip
      }
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

    def display_response(app = nil)
      r = responses(app)
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
        r.compact.join(', ')
      end
    end

    def conditional_match(answer_sheet)
      has_answer?(conditional_answers, answer_sheet) || 
        (responses(answer_sheet).empty? && conditional_answers.empty?)
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
