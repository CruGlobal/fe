require 'rails_helper'

describe 'AnswerSheet#answers_digest', type: :model do
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

  it 'returns a consistent digest for the same answers' do
    create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'hello')
    create(:answer, answer_sheet_id: answer_sheet.id, question_id: element2.id, value: 'world')

    digest1 = answer_sheet.answers_digest(page)
    digest2 = answer_sheet.answers_digest(page)
    expect(digest1).to eq(digest2)
    expect(digest1).to match(/\A[a-f0-9]{32}\z/)
  end

  it 'returns a different digest when answers change' do
    answer = create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'hello')

    digest_before = answer_sheet.answers_digest(page)

    answer.update!(value: 'changed')

    digest_after = answer_sheet.answers_digest(page)
    expect(digest_before).not_to eq(digest_after)
  end

  it 'returns a different digest when a new answer is added' do
    digest_before = answer_sheet.answers_digest(page)

    create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'new')

    digest_after = answer_sheet.answers_digest(page)
    expect(digest_before).not_to eq(digest_after)
  end

  it 'returns a different digest when an answer is removed' do
    answer = create(:answer, answer_sheet_id: answer_sheet.id, question_id: element1.id, value: 'hello')

    digest_before = answer_sheet.answers_digest(page)

    answer.destroy!

    digest_after = answer_sheet.answers_digest(page)
    expect(digest_before).not_to eq(digest_after)
  end

  it 'returns same digest for a page with no answers' do
    digest = answer_sheet.answers_digest(page)
    expect(digest).to eq(Digest::MD5.hexdigest(""))
  end
end

describe Fe::AnswerPagesController, '#update concurrency', type: :controller do
  let(:answer_sheet) { create(:answer_sheet) }
  let(:page) { create(:page) }
  let(:question_sheet) { page.question_sheet }
  let(:element) { create(:text_field_element) }

  before do
    create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
    create(:page_element, element: element, page: page)
    page.rebuild_all_element_ids
  end

  it 'saves successfully with a valid digest' do
    digest = answer_sheet.answers_digest(page)

    put :update, params: {
      answers: { "#{element.id}" => 'new answer' },
      answers_digest: digest,
      id: page.id,
      answer_sheet_id: answer_sheet.id
    }, xhr: true

    expect(response).to have_http_status(:ok)
    expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('new answer')
  end

  it 'rejects with 409 when digest is stale' do
    stale_digest = answer_sheet.answers_digest(page)

    # Simulate another tab saving an answer
    create(:answer, answer_sheet_id: answer_sheet.id, question_id: element.id, value: 'from other tab')

    put :update, params: {
      answers: { "#{element.id}" => 'my answer' },
      answers_digest: stale_digest,
      id: page.id,
      answer_sheet_id: answer_sheet.id
    }, xhr: true

    expect(response).to have_http_status(:conflict)
    # Verify the original answer was not overwritten
    expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('from other tab')
  end

  it 'saves successfully without a digest (backwards compatibility)' do
    put :update, params: {
      answers: { "#{element.id}" => 'answer here' },
      id: page.id,
      answer_sheet_id: answer_sheet.id
    }, xhr: true

    expect(response).to have_http_status(:ok)
    expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('answer here')
  end
end
