require 'acts_as_list'
module Fe
  class PageElement < ApplicationRecord
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)
    acts_as_list scope: :page_id
    belongs_to :page, touch: true
    belongs_to :element

    after_save :save_element
    before_create :set_position
    after_destroy :rebuild_page_all_element_ids

    def set_position
      self.position ||= (page.page_elements.last.try(:position) + 1) || page.elements.last.try(:position) || 0
    end

    # need conditional callbacks run
    def save_element
      element.save!
    end

    def rebuild_page_all_element_ids
      page.rebuild_all_element_ids
    end
  end
end
