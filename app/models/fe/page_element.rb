require 'acts_as_list'
module Fe
  class PageElement < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)
    acts_as_list :scope => :page_id
    belongs_to :page
    belongs_to :element
  end
end
