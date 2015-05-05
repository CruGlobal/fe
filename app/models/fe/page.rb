require 'acts_as_list'
module Fe
  class Page < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    belongs_to :question_sheet

    has_many :page_elements, -> { order(:position) },
             dependent: :destroy

    has_many :elements, -> { order(Fe::PageElement.table_name + '.position') },
             through: :page_elements

    has_many :question_grid_with_totals, -> { where("kind = 'Fe::QuestionGridWithTotal'") },
             through: :page_elements,
             source: :element

    has_many :questions, -> { questions.order(Fe::PageElement.table_name + '.position') },
             through: :page_elements,
             source: :element

    has_many :question_grids, -> { where("kind = 'Fe::QuestionGrid'") },
             through: :page_elements,
             source: :element

    # has_many :conditions, :class_name => "Condition", :foreign_key => "toggle_page_id",   # conditions associated with page as a whole
    #         conditions: 'toggle_id is NULL', :dependent => :nullify

    acts_as_list :column => :number, :scope => :question_sheet_id

    scope :visible, -> { where(:hidden => false) }

    # callbacks
    before_validation :set_default_label, :on => :create    # Page x

    # validation
    validates_presence_of :label, :number
    validates_length_of :label, :maximum => 100, :allow_nil => true

    # validates_uniqueness_of :number, :scope => :question_sheet_id

    validates_numericality_of :number, :only_integer => true

    # a page is disabled if there is a condition, and that condition evaluates to false
    # could set multiple conditions to influence this question, in which case all must be met
    # def active?
    #   # find first condition that doesn't pass (nil if all pass)
    #   self.conditions.detect { |c| !c.evaluate? }.nil?  # true if all pass
    # end
    #
    # def question?
    #   false
    # end

    def has_questions?
      all_questions.present?
    end

    def all_questions
      all_elements.questions
    end

    def questions_before_position(position)
      self.elements.where(["#{Fe::PageElement.table_name}.position < ?", position])
    end

    # Include nested elements
    def all_elements
      rebuild_all_element_ids if all_element_ids.nil?
      ids = all_element_ids.split(',')
      ids.present? ? Element.where(id: ids).order(:position) : Element.where("1 = 0")
    end

    def rebuild_all_element_ids
      self.update_column :all_element_ids, (elements + elements.collect(&:all_elements)).flatten.collect(&:id).join(',')
    end

    def copy_to(question_sheet)
      new_page = Fe::Page.new(self.attributes.merge(id: nil))
      new_page.question_sheet_id = question_sheet.id
      new_page.save(:validate => false)
      self.elements.each do |element|
        if !question_sheet.archived? && element.reuseable?
          Fe::PageElement.create(:element => element, :page => new_page)
        else
          element.duplicate(new_page)
        end
      end
    end

    def complete?(answer_sheet)
      return true if question_sheet.hidden_pages(answer_sheet).include?(self)
      prev_el = nil
      all_elements.all? {|e| 
        complete = !e.required?(answer_sheet) || e.has_response?(answer_sheet)
        prev_el = e
        complete
      }
    end

    def started?(answer_sheet)
      all_elements.any? {|e| e.has_response?(answer_sheet)}
    end

    def has_questions?
      all_elements.any? {|e| e.is_a?(Question)}
    end

    private

    # next unused label with "Page" prefix
    def set_default_label
      self.label = Fe.next_label("Page", Fe::Page.untitled_labels(self.question_sheet)) if self.label.blank?
    end

    def self.untitled_labels(sheet)
      sheet ? sheet.pages.where("label like 'Page %'").map {|p| p.label} : []
    end
  end
end
