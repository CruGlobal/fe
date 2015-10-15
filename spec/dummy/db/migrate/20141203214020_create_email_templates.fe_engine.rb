# This migration comes from fe_engine (originally 20131003044518)
class CreateEmailTemplates < ActiveRecord::Migration
  def up
    create_table Fe::EmailTemplate.table_name do |t|
      t.string  :name, :limit => 1000, :null => false
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
