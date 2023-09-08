class CreateEmailTemplates < ActiveRecord::Migration[4.2]
  def up
    create_table Fe::EmailTemplate.table_name do |t|
      t.string  :name, limit: 1000, null: false
      t.text    :content
      t.boolean :enabled
      t.string  :subject
      
      t.timestamps
    end
    # add_index Fe::EmailTemplate.table_name, :name
  end

  def down
    remove_table Fe::EmailTemplate.table_name
  end
end
