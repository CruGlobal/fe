require 'rails_helper'

describe Fe::AnswerPagesController, 'optimistic concurrency', type: :controller do
  let(:answer_sheet) { create(:answer_sheet) }
  let(:page) { create(:page) }
  let(:question_sheet) { page.question_sheet }
  let(:element1) { create(:text_field_element) }
  let(:element2) { create(:text_field_element) }

  before do
    create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
    create(:page_element, element: element1, page: page)
    create(:page_element, element: element2, page: page)
    page.rebuild_all_element_ids
  end

  describe 'full round-trip: load → save → concurrent edit → stale save' do
    it 'allows first save, rejects second save with stale digest' do
      # === Tab A loads the page and gets the initial digest ===
      digest_a = answer_sheet.answers_digest(page)

      # === Tab B loads the same page at the same time ===
      digest_b = digest_a  # identical, both loaded before any changes

      # === Tab A saves their answers (succeeds) ===
      put :update, params: {
        answers: { element1.id.to_s => 'Tab A answer 1', element2.id.to_s => 'Tab A answer 2' },
        answers_digest: digest_a,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('Tab A answer 1')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element2.id).value).to eq('Tab A answer 2')

      # === Tab B tries to save with the now-stale digest (rejected) ===
      put :update, params: {
        answers: { element1.id.to_s => 'Tab B answer 1', element2.id.to_s => 'Tab B answer 2' },
        answers_digest: digest_b,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:conflict)

      # Tab A's answers are preserved
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('Tab A answer 1')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element2.id).value).to eq('Tab A answer 2')
    end
  end

  describe 'successive saves from the same tab using updated digests' do
    it 'allows multiple saves when digest is refreshed each time' do
      digest = answer_sheet.answers_digest(page)

      # First save
      put :update, params: {
        answers: { element1.id.to_s => 'first draft' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)

      # Get the new digest (simulating what the JS response updates in the hidden field)
      new_digest = answer_sheet.answers_digest(page)
      expect(new_digest).not_to eq(digest)

      # Second save with updated digest
      put :update, params: {
        answers: { element1.id.to_s => 'second draft' },
        answers_digest: new_digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('second draft')
    end
  end

  describe 'auto-save race between two tabs' do
    it 'first auto-save wins, second is rejected, third with fresh digest succeeds' do
      # Both tabs load
      digest = answer_sheet.answers_digest(page)

      # Tab A auto-saves (succeeds)
      put :update, params: {
        answers: { element1.id.to_s => 'auto A' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true
      expect(response).to have_http_status(:ok)

      # Tab B auto-saves with stale digest (rejected)
      put :update, params: {
        answers: { element1.id.to_s => 'auto B' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true
      expect(response).to have_http_status(:conflict)

      # Tab B reloads the page, gets fresh digest, re-saves (succeeds)
      fresh_digest = answer_sheet.answers_digest(page)
      put :update, params: {
        answers: { element1.id.to_s => 'auto B retry' },
        answers_digest: fresh_digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true
      expect(response).to have_http_status(:ok)
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('auto B retry')
    end
  end

  describe 'backwards compatibility' do
    it 'allows save without digest param (old client)' do
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'existing')

      put :update, params: {
        answers: { element1.id.to_s => 'updated' },
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('updated')
    end
  end

  describe 'blank-form protection' do
    it 'rejects when 2+ text fields would overwrite non-blank answers with blanks' do
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'existing 1')
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element2.id, value: 'existing 2')
      digest = answer_sheet.answers_digest(page)

      put :update, params: {
        answers: { element1.id.to_s => '', element2.id.to_s => '' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:unprocessable_entity)
      # Existing answers are preserved
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('existing 1')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element2.id).value).to eq('existing 2')
    end

    it 'allows blanking a single text field (legitimate clear)' do
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'existing 1')
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element2.id, value: 'existing 2')
      digest = answer_sheet.answers_digest(page)

      put :update, params: {
        answers: { element1.id.to_s => '', element2.id.to_s => 'still here' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)
    end

    it 'allows submitting blanks when answers were already blank' do
      digest = answer_sheet.answers_digest(page)

      put :update, params: {
        answers: { element1.id.to_s => '', element2.id.to_s => '' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)
    end

    it 'works without digest param (old client still gets blank protection)' do
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'existing 1')
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: element2.id, value: 'existing 2')

      put :update, params: {
        answers: { element1.id.to_s => '', element2.id.to_s => '' },
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element1.id).value).to eq('existing 1')
    end

    it 'does not trigger for non-text-field questions' do
      # Replace text fields with choice fields
      page.page_elements.destroy_all
      choice1 = create(:choice_field_element)
      choice2 = create(:choice_field_element)
      create(:page_element, element: choice1, page: page)
      create(:page_element, element: choice2, page: page)
      page.rebuild_all_element_ids

      create(:answer, answer_sheet_id: answer_sheet.id, question_id: choice1.id, value: 'Choice One')
      create(:answer, answer_sheet_id: answer_sheet.id, question_id: choice2.id, value: 'Choice Two')
      digest = answer_sheet.answers_digest(page)

      put :update, params: {
        answers: { choice1.id.to_s => '', choice2.id.to_s => '' },
        answers_digest: digest,
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(response).to have_http_status(:ok)
    end
  end
end
