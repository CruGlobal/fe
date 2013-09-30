module Qe
  class Condition < ActiveRecord::Base

    module M
      extend ActiveSupport::Concern
      
      included do
        # self.table_name = "#{self.table_name}"
        
        belongs_to :question_sheet
        belongs_to :trigger, :class_name => "Question", :foreign_key => "trigger_id"

        validates_presence_of :expression
        validates_length_of :expression, :maximum => 255, :allow_nil => true  
      end

      # evaluate triggering element against expression and return match|nil
      def evaluate?
        true
        # answers = self.trigger.response # answers loaded?
        # expression = self.expression.downcase
        # answers.find {|answer| answer = answer.downcase; eval(expression)}
      end
      
      
      # TODO 
      # the model should NOT be responsible for generating view returned javascript
      # 
      # javascript to toggle pages/elements based on the "response"
      def trigger_js     
        # will find the first answer (if multiple/checkboxes) where the expression evaluates to true (downcase both to be case insensitive)
        # if no match, disabled will be true, otherwise false
        js = <<-JS
        disabled = (response.find(function(answer) {
          answer = toLowerCase(answer);
          return eval("#{escape_javascript(self.expression.downcase)}");
        }) == undefined);
        JS
        
        if toggle_id.nil?
          # toggling a whole page (link), which will affect final page validation
        else
          # toggling an element (form element)... if page is loaded/cached (if not, the server-side will take care of it on load)
          js = js + <<-JS
          if(page_handler.isPageLoaded('page_#{self.toggle_page_id}'))
          {
            $('element_#{self.toggle_id}').disabled = disabled;
          }
          JS
        end
        
        js
      end
    end

    include M
  end
end
