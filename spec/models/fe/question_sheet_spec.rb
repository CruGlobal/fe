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

  context '#all_elements' do
    it 'should include elements in a grid' do
      s = create(:question_sheet)
      p = create(:page, question_sheet: s)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      tf1 = create(:text_field_element, question_grid: e)
      tf2 = create(:text_field_element) # add directly to page
      create(:page_element, page: p, element: tf2)
      section = create(:section, question_grid: e)
      p.reload # get the updated all_element_ids column
      expect(s.all_elements).to eq([e, tf1, tf2, section])
    end
    it 'should include elements across multiple pages' do
      s = create(:question_sheet)

      # P1
      p1 = create(:page, question_sheet: s)

      # grid pg1
      g1 = create(:question_grid)
      create(:page_element, page: p1, element: g1)
      tf1 = create(:text_field_element, question_grid: g1)
      s1 = create(:section, question_grid: g1)

      # tf added directly to pg1
      tf2 = create(:text_field_element)
      create(:page_element, page: p1, element: tf2)

      # P2
      p2 = create(:page, question_sheet: s)

      # grid pg2
      g2 = create(:question_grid)
      create(:page_element, page: p2, element: g2)
      tf3 = create(:text_field_element, question_grid: g2)
      s2 = create(:section, question_grid: g2)

      # tf added directly to pg2
      tf4 = create(:text_field_element)
      create(:page_element, page: p2, element: tf4)

      p1.reload # get the updated all_element_ids column
      p2.reload # get the updated all_element_ids column
      expect(s.all_elements).to eq([g1, tf1, s1, tf2, g2, tf3, s2, tf4])
    end
  end

  context '#elements' do
    it 'should not include elements in a grid' do
      s = create(:question_sheet)
      p = create(:page, question_sheet: s)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      tf1 = create(:text_field_element, question_grid: e) # shouldn't be included because it's in grid
      tf2 = create(:text_field_element)
      create(:page_element, page: p, element: tf2)
      create(:section, question_grid: e) # shouldn't be included because it's in grid
      p.reload # get the updated all_element_ids column
      expect(s.elements).to eq([e, tf2])
    end
  end
end
