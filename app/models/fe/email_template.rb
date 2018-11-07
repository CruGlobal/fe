module Fe
  class EmailTemplate < ApplicationRecord
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    validates_presence_of :name
  end
end
