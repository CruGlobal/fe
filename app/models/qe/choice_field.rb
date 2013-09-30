# TODO
# this should be required somewhere else
require 'net/http'

begin
  require 'xml/libxml'
rescue LoadError
  require 'rexml/document'
end

# ChoiceField
# - a question that allows the selection of one or more choices

module Qe
  class ChoiceField < Question

    module M
      extend ActiveSupport::Concern

      included do
        has_many :elements, 
          :foreign_key => "conditional_id", 
          :dependent => :nullify#, :order => :position
      end
        
      # Returns choices stored one per line in content field
      def choices
        retVal = Array.new 
        if ['yes-no', 'acceptance'].include?(self.style)
          return [["Yes",1],["No",0]]
        elsif !source.blank?
          begin
            doc = XML::Document.file(source)
            options = doc.find(text_xpath).collect { |n| n.content }
            values = doc.find(value_xpath).collect { |n| n.content }
            retVal = [options, values].transpose
          rescue NameError
            doc = REXML::Document.new Net::HTTP.get_response(URI.parse(source)).body
            retVal = [ doc.elements.collect(text_xpath){|c|c.text}, doc.elements.collect(value_xpath){|c|c.text} ].transpose.sort
          end
        elsif !content.nil?
          content.split("\n").each do |opt|
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
        case self.style
                        when 'qe/checkbox'    then 'qe/checkbox_field'
                        when 'qe/drop-down'   then 'qe/drop_down_field'
                        when 'qe/radio'       then 'qe/radio_button_field'
                        when 'qe/yes-no'      then 'qe/yes_no'
                        when 'qe/rating'      then 'qe/rating'
                        when 'qe/acceptance'  then 'qe/acceptance'
                        when 'qe/country'     then 'qe/country'
                        else 'qe/drop_down_field'

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
      
      def display_response(app=nil)
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
          r.compact.join(", ")
        end
      end

      protected
      def is_true(val)
        [1,'1',true,'true','Yes','yes'].include?(val) # note: true = anything but false | nil
      end

      def is_false(val)
        # returns false if false (a bit odd)
        [0,'0',false,'false','No','no'].include?(val)
      end
    end

    include M
  end
end
