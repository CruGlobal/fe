require 'acts_as_list'
module Fe
  class Page < ApplicationRecord
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    attr_accessor :old_id

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

    # has_many :conditions, class_name: "Condition", foreign_key: "toggle_page_id",   # conditions associated with page as a whole
    #         conditions: 'toggle_id is NULL', dependent: :nullify

    acts_as_list column: :number, scope: :question_sheet_id

    scope :visible, -> { where(hidden: false) }

    # callbacks
    before_validation :set_default_label, on: :create    # Page x

    # validation
    validates_presence_of :label, :number
    validates_length_of :label, maximum: 100, allow_nil: true

    # validates_uniqueness_of :number, scope: :question_sheet_id

    validates_numericality_of :number, only_integer: true

    # NOTE: You may need config.active_record.yaml_column_permitted_classes = [Hash, ActiveSupport::HashWithIndifferentAccess]
    # in config/application.rb or you may get Psych::DisallowedClass trying to use label_translations
    serialize :label_translations, Rails::VERSION::MAJOR < 7 ? Hash : { type: Hash }

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

    def conditionally_visible?
      question_sheet&.all_elements&.where(conditional_type: 'Fe::Page', conditional_id: self)&.any?
    end

    # any page that's conditionally visible should not use cache, there are race conditions otherwise
    # that happen when the conditional value is set and the now visible page loaded in ajax
    def no_cache
      conditionally_visible? || self[:no_cache]
    end

    def label(locale = nil)
      label_translations[locale] || self[:label]
    end

    # returns true if there is a question element on the page, including one inside a grid
    def has_questions?
      all_questions.any?
    end

    def all_questions
      all_elements.questions
    end

    def questions_before_position(position)
      self.elements.where(["#{Fe::PageElement.table_name}.position < ?", position])
    end

    # Include nested elements
    def all_elements
      ids = all_element_ids_arr
      order = ids.collect{ |id| "id=#{id} DESC" }.join(', ')
      ids.present? ? Element.where(id: ids).order(Arel.sql(order)) : Element.where(id: [])
    end

    def all_element_ids
      rebuild_all_element_ids if self[:all_element_ids].nil?
      self[:all_element_ids]
    end

    def all_element_ids_arr
      @all_element_ids_arr ||= all_element_ids.split(',').collect(&:to_i)
    end

    def rebuild_all_element_ids
      self.update_column :all_element_ids, elements.collect{ |e| [e] + e.all_elements }.flatten.collect(&:id).join(',')
    end

    def copy_to(question_sheet)
      new_page = Fe::Page.new(self.attributes.merge(id: nil))
      new_page.question_sheet_id = question_sheet.id
      new_page.save(validate: false)
      self.elements.each do |element|
        if !question_sheet.archived? && element.reuseable?
          Fe::PageElement.create(element: element, page: new_page)
        else
          element.duplicate(new_page)
        end
      end
      new_page.rebuild_all_element_ids
      new_page
    end

    def hidden?(answer_sheet)
      return true if hidden

      @hidden_cache ||= {}
      return @hidden_cache[answer_sheet] if !@hidden_cache[answer_sheet].nil?

      unless conditionally_visible?
        @hidden_cache[answer_sheet] = false
        return false
      end

      # if any of the conditional questions matches, it's visible
      r = !question_sheet.all_elements.where(conditional_type: 'Fe::Page', conditional_id: self).any?{ |e|
        e.visible?(answer_sheet) && e.conditional_match(answer_sheet)
      }
      @hidden_cache[answer_sheet] = r
      return r
    end

    def clear_hidden_cache
      @hidden_cache = nil
    end

    def complete?(answer_sheet)
      return true if hidden?(answer_sheet)

      all_elements.all? {|e|
        e.hidden?(answer_sheet, self) || !e.required?(answer_sheet, self) || e.has_response?(answer_sheet)
      }
    end

    def started?(answer_sheet)
      all_questions.any? {|e| e.has_response?(answer_sheet)}
    end

    def all_hidden_elements(answer_sheet)
      @all_hidden_elements ||= {}
      @all_hidden_elements[answer_sheet.cache_key] ||= build_all_hidden_elements(answer_sheet)
    end

    def build_all_hidden_elements(answer_sheet)
      @all_hidden_elements ||= {}
      @all_hidden_elements[answer_sheet.cache_key] = []
      all_elements.each do |e|
        next if @all_hidden_elements[answer_sheet.cache_key].include?(e)
        if e.hidden_by_choice_field?(answer_sheet) || e.hidden_by_conditional?(answer_sheet, self)
          @all_hidden_elements[answer_sheet.cache_key] += ([e] + e.all_elements)
          @all_hidden_elements[answer_sheet.cache_key].uniq!
        end
      end
      @all_hidden_elements[answer_sheet.cache_key]
    end

    def clear_all_hidden_elements
      @all_hidden_elements = nil
    end

    def export_hash
      base_attributes = self.attributes.to_hash
      base_attributes[:elements] = elements.collect(&:export_hash)
      base_attributes.delete(:id)
      base_attributes[:question_sheet_id] = :question_sheet_id
      base_attributes
    end

    def export_to_yaml
      export_hash.to_yaml
    end

    def self.create_from_import(page_data, question_sheet)
      elements = page_data.delete(:elements)
      page_data.delete(:all_element_ids) # this can get build again
      page_data[:old_id] = page_data.delete('id')
      page_data[:question_sheet_id] = question_sheet.id
      puts("Import page from data #{page_data}")
      page = Fe::Page.create!(page_data)
      elements.each do |el|
        page.elements << Fe::Element.create_from_import(el, page, question_sheet)
      end
      page.rebuild_all_element_ids
      page
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
