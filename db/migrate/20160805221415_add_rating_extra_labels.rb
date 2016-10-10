class AddRatingExtraLabels < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :rating_before_label, :text
    add_column Fe::Element.table_name, :rating_after_label, :text
    add_column Fe::Element.table_name, :rating_na_label, :text
    add_column Fe::Element.table_name, :rating_before_label_translations, :text
    add_column Fe::Element.table_name, :rating_after_label_translations, :text
    add_column Fe::Element.table_name, :rating_na_label_translations, :text
  end
end
