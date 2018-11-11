class RemoveShortValueColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column Fe::Answer.table_name, :short_value
  end
end
