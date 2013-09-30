require 'acts_as_list'

class PageElement < ActiveRecord::Base
  set_table_name "#{Qe.table_name_prefix}#{self.table_name}"
  acts_as_list :scope => :page_id
  belongs_to :page
  belongs_to :element
end
