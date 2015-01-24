# This migration comes from fe_engine (originally 20131003044436)
class AddElementAndAnswerFields < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :conditional_id,     :integer
    add_column Fe::Element.table_name, :tooltip,            :text
    add_column Fe::Element.table_name, :hide_label,         :boolean, :default => false, :nil => false
    add_column Fe::Element.table_name, :hide_option_labels, :boolean, :default => false, :nil => false

    #add_index Fe::Element.table_name, :conditional_id
  end
end
