class AddShareToElements < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::Element.table_name, :share, :boolean, default: false
  end
end
