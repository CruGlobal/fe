# This migration comes from fe_engine (originally 20131003041856)
  class Core < ActiveRecord::Migration
  def change
    create_table Fe::QuestionSheet.table_name do |t|
      t.string  :label,    :limit => 100,       :null => false   # name used internally in admin
      t.boolean :archived, :default => false,   :nil => false
      t.timestamps
    end

    create_table Fe.answer_sheet_class.constantize.table_name do |t|
      t.integer   :applicant_id
      t.string    :status
      t.datetime  :submitted_at
      t.timestamps
    end

    add_index Fe.answer_sheet_class.constantize.table_name, :applicant_id, name: 'question_sheet_id'

    create_table Fe::Page.table_name do |t|
      t.integer :question_sheet_id,  :null => false
      t.string  :label,     :limit => 60, :null => false    # page title
      t.integer :number                                     # page number (order)
      t.boolean :no_cache,  :default => false
      t.boolean :hidden,    :default => false
      t.timestamps
    end

    create_table Fe::Element.table_name do |t|
      t.integer :question_grid_id,   :null => true
      t.string  :kind,               :limit => 40,   :null => false  # single table inheritance: class name
      t.string  :style,              :limit => 40                    # render style
      t.string  :label,              :limit => 255                   # question label, section heading
      t.text    :content,              :null => true                 # for content/instructions, and for choices (one per line)
      t.boolean :required                                            # question is required?
      t.string  :slug,               :limit => 36                    # variable reference
      t.integer :position
      t.string  :object_name,        :attribute_name
      t.string  :source
      t.string  :value_xpath
      t.string  :text_xpath
      t.string  :cols
      t.boolean :is_confidential, :default => false
      t.string  :total_cols
      t.string  :css_id
      t.string  :css_class
      t.integer :question_sheet_id, :null => false
      t.timestamps
    end
    add_index Fe::Element.table_name, :slug
    
    create_table Fe::PageElement.table_name do |t|
      t.integer :page_id
      t.integer :element_id
      t.integer :position
      t.timestamps
    end

    add_index Fe::PageElement.table_name, [:page_id, :element_id], name: 'page_element'


    create_table Fe::Answer.table_name do |t|
      t.integer  :answer_sheet_id,  :null => false
      t.integer  :question_id,      :null => false
      t.text     :value
      t.string   :short_value,         :null => true, :limit => 255   # indexed copy of :value
      # paperclip columns
      t.integer  :attachment_file_size
      t.string   :attachment_content_type
      t.string   :attachment_file_name
      t.datetime :attachment_updated_at
      t.timestamps
    end

    add_index Fe::Answer.table_name, :short_value
    add_index Fe::Answer.table_name, [:answer_sheet_id, :question_id], name: 'answer_sheet_question'

    create_table Fe::Condition.table_name do |t|
      t.integer :question_sheet_id,  :null => false
      t.integer :trigger_id,            :null => false
      t.string  :expression,            :null => false,  :limit  => 255
      t.integer :toggle_page_id,        :null => false
      t.integer :toggle_id,             :null => true    # null if toggles whole page
      t.timestamps
    end

    add_index Fe::Condition.table_name, :question_sheet_id
    add_index Fe::Condition.table_name, :trigger_id
    add_index Fe::Condition.table_name, :toggle_page_id
    add_index Fe::Condition.table_name, :toggle_id

  end
end
