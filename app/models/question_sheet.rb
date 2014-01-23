# QuestionSheet represents a particular form

class QuestionSheet < ActiveRecord::Base
  self.table_name = "#{Qe.table_name_prefix}#{self.table_name}"

  has_many :pages, -> { order('number') },
    :dependent => :destroy

  # has_many :elements
  # has_many :questions

  has_many :answer_sheet_question_sheets

  has_many :answer_sheets,
    :through => :answer_sheet_question_sheets

  scope :active, -> { where(:archived => false) }
  scope :archived, -> { where(:archived => true) }

  validates_presence_of :label
#  validates_length_of :label, :maximum => 60, :allow_nil => true
  validates_uniqueness_of :label

  before_destroy :check_for_answers

  # create a new form with a page already attached
  def self.new_with_page
    question_sheet = self.new(:label => next_label)
    question_sheet.pages.build(:label => 'Page 1', :number => 1)
    question_sheet
  end

  def questions
    pages.collect(&:questions).flatten
  end

  def elements
    pages.collect(&:elements).flatten
  end

  # Pages get duplicated
  # Question elements get associated
  # non-question elements get cloned
  def duplicate
    new_sheet = QuestionSheet.new(self.attributes.except('id'))
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
    Qe.next_label("Untitled form", untitled_labels)
  end

  # returns a list of existing Untitled forms
  # (having a separate method makes it easy to mock in the spec)
  def self.untitled_labels
    QuestionSheet.find(:all, :conditions => %{label like 'Untitled form%'}).map {|s| s.label}
  end

  def check_for_answers

  end

end
