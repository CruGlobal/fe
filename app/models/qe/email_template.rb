class EmailTemplate < ActiveRecord::Base
  set_table_name "#{Qe.table_name_prefix}#{self.table_name}"
  
  validates_presence_of :name
end
