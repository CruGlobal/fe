class RemoveShortValueColumn < ActiveRecord::Migration
  def change
    remove_column Fe::Answer.table_name, :short_value
  end
end
