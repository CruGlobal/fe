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

  context 'saving' do
    let(:e) { create(:text_field_element) }
    let(:app) { create(:text_field_element) }
    let(:app2) { create(:text_field_element) }

    before do
      e.set_response('answer value', app)
    end

    context '#save_file' do
      it ' checks that the answer sheet that calls set_response is the same one that calls save' do
        expect {
          e.save_file(app2, nil)
        }.to raise_error(RuntimeError, "Trying to save answers to a different answer sheet than the one given in set_response")
      end
    end

    context '#delete_file' do
      it ' checks that the answer sheet that calls set_response is the same one that calls delete' do
        expect {
          e.delete_file(app2, nil)
        }.to raise_error(RuntimeError, "Trying to save answers to a different answer sheet than the one given in set_response")
      end

      it 'deletes the given answer record' do
        answer_sheet = create(:answer_sheet)
        question = create(:attachment_field_element)
        answer = create(:answer, attachment_file_name: 'test_file', answer_sheet: answer_sheet, question: question)
        question.set_response('', answer_sheet)
        question.delete_file(answer_sheet, answer)
        expect{answer.reload}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context '#save_response' do
      it ' checks that the answer sheet that calls set_response is the same one that calls save' do
        expect {
          e.save_response(app2)
        }.to raise_error(RuntimeError, "Trying to save answers to a different answer sheet than the one given in set_response")
      end
    end
  end
end
