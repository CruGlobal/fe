# This migration comes from fe_engine (originally 20141103204704)
class RemoveShortValueColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column Fe::Answer.table_name, :short_value
  end
end
