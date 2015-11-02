class SwitchConditionalAnswerSeparatorToSemicolon < ActiveRecord::Migration
  def change
    Fe::Element.where("conditional_answer IS NOT NULL AND conditional_answer != ''").each do |e|
      e.update_column :conditional_answer, e.conditional_answer.gsub(',', ';')
    end
  end
end
