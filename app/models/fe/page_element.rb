require 'acts_as_list'
module Fe
  class PageElement < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)
    acts_as_list :scope => :page_id
    belongs_to :page
    belongs_to :element

    after_save :set_conditional_element
    after_save :update_any_previous_conditional_elements
    before_create :set_position

    def set_position
      self.position ||= (page.page_elements.last.try(:position) + 1) || page.elements.last.try(:position) || 0
    end

    def set_conditional_element
      element.set_conditional_element
    end

    def update_any_previous_conditional_elements
      element.update_any_previous_conditional_elements
    end
  end
end
