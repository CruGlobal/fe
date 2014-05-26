# Element represents a section, question or content element on the question sheet
module Fe
  class Element < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    belongs_to :question_grid,
               :class_name => "Fe::QuestionGrid",
               :foreign_key => "question_grid_id"

    belongs_to :choice_field,
               :class_name => "Fe::ChoiceField",
               :foreign_key => "conditional_id"

    self.inheritance_column = :kind

    has_many :page_elements, :dependent => :destroy
    has_many :pages, :through => :page_elements

    scope :active, -> { select("distinct(#{Fe::Element.table_name}.id), #{Fe::Element.table_name}.*").where(Fe::QuestionSheet.table_name + '.archived' => false).joins({:pages => :question_sheet}) }

    validates_presence_of :kind
    validates_presence_of :style
    # validates_presence_of :label, :style, :on => :update

    validates_length_of :kind, :maximum => 40, :allow_nil => true
    validates_length_of :style, :maximum => 40, :allow_nil => true
    # validates_length_of :label, :maximum => 255, :allow_nil => true

    before_validation :set_defaults, :on => :create

    # HUMANIZED_ATTRIBUTES = {
    #   :slug => "Variable"
    # }changed.include?('address1')
    #
    # def self.human_attrib_name(attr)
    #   HUMANIZED_ATTRIBUTES[attr.to_sym] || super
    # end

    def has_response?(answer_sheet = nil)
      false
    end

    def limit(answer_sheet = nil)
      if answer_sheet && object_name.present? && attribute_name.present?
        begin
          unless eval("answer_sheet." + self.object_name + ".nil?")
            klass = eval("answer_sheet." + self.object_name + ".class")
            column = klass.columns_hash[self.attribute_name]
            column.limit
          end
        rescue
          nil
        end
      end
    end

    def required?(answer_sheet = nil)
      required == true
    end

    def position(page = nil)
      if page
        page_elements.where(:page_id => page.id).first.try(:position)
      else
        self[:position]
      end
    end

    def set_position(position, page = nil)
      if page
        pe = page_elements.where(:page_id => page.id).first
        pe.update_attribute(:position, position) if pe
      else
        self[:position] = position
      end
      position
    end

    def page_id(page = nil)
      if page
        page.id
      else
        pages.first.id
      end
    end

    def question?
      self.kind_of?(Question)
    end


    # by default the partial for an element matches the class name (override as necessary)
    def ptemplate
      self.class.to_s.underscore
    end

    # copy an item and all it's children
    def duplicate(page, parent = nil)
      new_element = self.class.new(self.attributes.except('id', 'created_at', 'updated_at'))
      case parent.class.to_s
        when Fe::ChoiceField
          new_element.conditional_id = parent.id
        when Fe::QuestionGrid, Fe::QuestionGridWithTotal
          new_element.question_grid_id = parent.id
      end
      new_element.save(:validate => false)
      Fe::PageElement.create(:element => new_element, :page => page) unless parent

      # duplicate children
      if respond_to?(:elements) && elements.present?
        elements.each {|e| e.duplicate(page, new_element)}
      end

      new_element
    end

    # include nested elements
    def all_elements
      if respond_to?(:elements)
        (elements + elements.collect(&:all_elements)).flatten
      else
        []
      end
    end

    def reuseable?
      (self.is_a?(Question) || self.is_a?(Fe::QuestionGrid) || self.is_a?(Fe::QuestionGridWithTotal))
    end

    def self.max_label_length
      @@max_label_length ||= Fe::Element.columns.find{ |c| c.name == "label" }.limit
    end

    protected
    def set_defaults
      if self.content.blank?
        case self.class.to_s
          when "Fe::ChoiceField" then self.content ||= "Choice One\nChoice Two\nChoice Three"
          when "Fe::Paragraph" then self.content ||="Lorem ipsum..."
        end
      end

      if self.style.blank?
        case self.class.to_s
          when 'Fe::TextField' then self.style ||= 'essay'
          when "Fe::DateField" then self.style ||= "date"
          when "Fe::FileField" then self.style ||= "file"
          when "Fe::Paragraph" then self.style ||= "paragraph"
          when "Fe::Section" then self.style ||= "section"
          when "Fe::ChoiceField" then self.style = "checkbox"
          when "Fe::QuestionGrid" then self.style ||= "grid"
          when "Fe::QuestionGridWithTotal" then self.style ||= "grid_with_total"
          when "Fe::SchoolPicker" then self.style ||= "school_picker"
          when "Fe::ProjectPreference" then self.style ||= "project_preference"
          when "Fe::StateChooser" then self.style ||= "state_chooser"
          when "Fe::ReferenceQuestion" then self.style ||= "peer"
          else
            self.style ||= self.class.to_s.underscore
        end
      end
    end

  end
end
