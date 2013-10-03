class QeCore < ActiveRecord::Migration
  def change
    create_table QuestionSheet.table_name do |t|
      t.string  :label,    :limit => 100,       :null => false   # name used internally in admin
      t.boolean :archived, :default => false,   :nil => false
      t.timestamps
    end
  
    create_table Page.table_name do |t|
      t.integer :question_sheet_id,  :null => false
      t.string  :label,     :limit => 60, :null => false    # page title
      t.integer :number                                     # page number (order)
      t.boolean :no_cache,  :default => false
      t.boolean :hidden,    :default => false
      t.timestamps
    end

    create_table Element.table_name do |t|
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
    add_index Element.table_name, :slug
    
    create_table PageElement.table_name do |t|
      t.integer :page_id
      t.integer :element_id
      t.integer :position
      t.timestamps
    end

    # mysql issue
    # Index name 'index_qe_elements_on_qe_question_sheet_id_and_position_and_qe_page_id' on table 'qe_elements' is too long; the limit is 64 characters
    # add_index Element.table_name, [:question_sheet_id, :position, :page_id], :unique => false
  
    create_table AnswerSheet.table_name do |t|
      t.integer   :question_sheet_id,  :null => false
      t.datetime  :completed_at,          :null => true  # null if incomplete
      t.timestamps
    end

    create_table Answer.table_name do |t|
      t.integer  :answer_sheet_id,  :null => false
      t.integer  :question_id,      :null => false
      t.text     :value
      t.string   :short_value,         :null => true, :limit => 255   # indexed copy of :response
      # paperclip columns
      t.integer  :attachment_file_size
      t.string   :attachment_content_type
      t.string   :attachment_file_name
      t.datetime :attachment_updated_at
      t.timestamps
    end   

    create_table Condition.table_name do |t|
      t.integer :question_sheet_id,  :null => false
      t.integer :trigger_id,            :null => false
      t.string  :expression,            :null => false,  :limit  => 255
      t.integer :toggle_page_id,        :null => false
      t.integer :toggle_id,             :null => true    # null if toggles whole page
      t.timestamps
    end
    
  end
end
