# QuestionSheet represents a particular form
module Fe
  class QuestionSheet < ActiveRecord::Base
    self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)

    has_many :pages, -> { order('number') },
             :dependent => :destroy

    has_many :answer_sheet_question_sheets

    has_many :answer_sheets,
             :through => :answer_sheet_question_sheets
    has_many :question_sheets,
             :through => :answer_sheet_question_sheets

    scope :active, -> { where(:archived => false) }
    scope :archived, -> { where(:archived => true) }

    validates_presence_of :label

    serialize :languages, Array

    before_destroy :check_for_answers

    # create a new form with a page already attached
    def self.new_with_page
      question_sheet = self.new(:label => next_label)
      question_sheet.pages.build(:label => 'Page 1', :number => 1)
      question_sheet
    end

    def questions
      all_elements.questions
    end

    def elements
      pages.collect(&:elements).flatten
    end

    def all_elements
      element_ids = pages.pluck(:all_element_ids).compact.join(',').split(',').find_all(&:present?)
      element_ids.present? ? Element.where(id: element_ids).order(element_ids.collect{ |id| "id=#{id} DESC" }.join(', ')) : Element.where("1 = 0")
    end

    # Pages get duplicated
    # Question elements get associated
    # non-question elements get cloned
    def duplicate
      new_sheet = QuestionSheet.new(self.attributes.merge(id: nil))
      new_sheet.label = self.label + ' - COPY'
      new_sheet.save(:validate => false)
      self.pages.each do |page|
        page.copy_to(new_sheet)
      end
      new_sheet
    end

    private

    # next unused label with "Untitled form" prefix
    def self.next_label
      Fe.next_label("Untitled form", untitled_labels)
    end

    # returns a list of existing Untitled forms
    # (having a separate method makes it easy to mock in the spec)
    def self.untitled_labels
      QuestionSheet.where("label LIKE ?", 'Untitled form%').map{|s| s.label }
    end

    def check_for_answers

    end

  end
end
