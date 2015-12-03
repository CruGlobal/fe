require 'rails_helper'

describe Fe::Question do
  it { expect have_many :conditions }
  it { expect have_many :dependents }
  it { expect have_many :sheet_answers }
  it { expect belong_to :related_question_sheet }
  
  # it { expect validate_format_of :slug }
  # it { expect validate_length_of :slug }
  # it { expect validate_uniqueness_of :slug }
  
  describe '#default_label?' do 
    it 'expect return true' do 
      question = Fe::Question.new
      #question.default_label?.expect be_true
      expect(question.default_label?).to eq(true)
    end
  end
  
  context 'slug' do
    let(:qs) { create(:question_sheet_with_pages) }
    let(:page) { qs.pages.first }
    let(:qs2) { create(:question_sheet_with_pages) }
    let(:page2) { qs2.pages.first }
    let(:e1) { create(:text_field_element, slug: 'test') }
    let(:e2) { create(:text_field_element) }

    before do
      e1.pages << page
    end

    it "doesn't let the same slug be used in the question sheet" do
      e2.pages << page
      e2.slug = 'test'
      e2.save
      expect(e2.errors.full_messages.join(', ')).to include('Slug must be unique (within the question sheet)')
    end
    it "lets two elements with the same slug save on different sheets" do
      e2.pages << page2
      e2.slug = 'test'
      expect(e2.save).to be true
    end
  end

end
