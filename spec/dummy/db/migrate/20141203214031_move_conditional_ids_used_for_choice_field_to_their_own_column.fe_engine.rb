# This migration comes from fe_engine (originally 20141109154522)
class MoveConditionalIdsUsedForChoiceFieldToTheirOwnColumn < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :choice_field_id, :integer
    Fe::Element.reset_column_information
    Fe::Element.where(conditional_type: nil).where("conditional_id is not null").update_all("choice_field_id = conditional_id, conditional_id = null")
  end
end
