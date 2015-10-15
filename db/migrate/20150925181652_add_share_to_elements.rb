class AddShareToElements < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :share, :boolean, default: false
  end
end
