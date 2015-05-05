require 'rails_helper'

describe Fe::QuestionSheet do
  it { expect have_many :pages }
  it { expect have_many :answer_sheets }
  it { expect validate_presence_of :label }
  it { expect validate_uniqueness_of :label }

  context '#questions_count' do
    it 'should count elements in a grid' do
      s = create(:question_sheet)
      p = create(:page, question_sheet: s)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      create(:text_field_element, question_grid: e)
      create(:section, question_grid: e) # this shouldn't get counted
      p.reload # get the updated all_element_ids column
      expect(s.questions_count).to eq(1)
    end
  end
end
