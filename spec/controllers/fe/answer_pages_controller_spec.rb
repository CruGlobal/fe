require 'rails_helper'

describe Fe::AnswerPagesController, type: :controller do
  context 'answer_sheet_type param' do
    it 'rejects a class that is not an allowed answer sheet type' do
      page = create(:page)
      expect {
        get :show, params: {id: page.id, answer_sheet_id: 1, answer_sheet_type: 'Kernel'}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
  context 'access control' do
    let(:answer_sheet) { create(:answer_sheet) }
    let(:page) { create(:page) }
    let(:element) { create(:text_field_element) }

    before do
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: page.question_sheet)
      create(:page_element, element: element, page: page)
    end

    it 'returns 403 on update and stores nothing when the host refuses' do
      create(:answer, answer_sheet: answer_sheet, question: element, value: 'before')
      allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(false)

      put :update, params: {
        answers: { "#{element.id}" => 'after' }, id: page.id, answer_sheet_id: answer_sheet.id
      }, xhr: true, format: :js

      expect(response).to have_http_status(:forbidden)
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('before')
    end
    it 'asks the host for :look on show' do
      expect(controller).to receive(:fe_can_use_answer_sheet?).with(answer_sheet, :look).and_return(false)
      get :show, params: {id: page.id, answer_sheet_id: answer_sheet.id}
      expect(response).to have_http_status(:forbidden)
    end

    context 'when a subclass re-declares before_action :get_answer_sheet' do
      controller(Fe::AnswerPagesController) { before_action :get_answer_sheet }

      it 'still asks the host, returns 403 on update and stores nothing' do
        filters = controller.class._process_action_callbacks.map(&:filter)
        expect(filters.index(:get_answer_sheet)).to be > filters.index(:fe_authorize_answer_sheet!)
        create(:answer, answer_sheet: answer_sheet, question: element, value: 'before')
        expect(controller).to receive(:fe_can_use_answer_sheet?).with(answer_sheet, :change).and_return(false)

        put :update, params: {
          answers: { "#{element.id}" => 'after' }, id: page.id, answer_sheet_id: answer_sheet.id
        }, xhr: true, format: :js

        expect(response).to have_http_status(:forbidden)
        expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('before')
      end
    end
  end
  context '#edit' do
    let(:answer_sheet) { create(:answer_sheet) }
    let(:page) { create(:page) }

    it 'should work' do
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      get :edit, params: {id: page.id, answer_sheet_id: answer_sheet.id}
      expect(response).to render_template('fe/answer_pages/_answer_page')
    end
    context 'filtering' do
      let(:el_confidential) { create(:text_field_element, is_confidential: true) }
      let(:el_visible) { create(:text_field_element, is_confidential: false) }
      let(:el_visible2) { create(:text_field_element, is_confidential: false) }

      before do
        page.elements << el_confidential << el_visible << el_visible2
        question_sheet = page.question_sheet
        create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      end

      it 'should filter out elements' do
        allow_any_instance_of(Fe::AnswerPagesController).to receive(:get_filter).and_return(filter_default: :show, filter: [ :is_confidential ])
        get :edit, params: {id: page.id, answer_sheet_id: answer_sheet.id}
        expect(assigns(:elements)).to_not include(el_confidential)
        expect(assigns(:elements)).to include(el_visible)
        expect(assigns(:elements)).to include(el_visible2)
      end
      it 'should filter in elements' do
        allow_any_instance_of(Fe::AnswerPagesController).to receive(:get_filter).and_return(filter_default: :hide, filter: [ :is_confidential ])
        get :edit, params: {id: page.id, answer_sheet_id: answer_sheet.id}
        expect(assigns(:elements)).to include(el_confidential)
        expect(assigns(:elements)).to_not include(el_visible)
        expect(assigns(:elements)).to_not include(el_visible2)
      end
    end
  end

  context '#update' do
    let(:answer_sheet) { create(:answer_sheet) }
    let(:page) { create(:page) }
    let(:question_sheet) { question_sheet = page.question_sheet }
    let(:element) { create(:text_field_element) }

    before do
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      create(:page_element, element: element, page: page)
    end

    it 'should work' do
      # ref
      reference_question = create(:reference_question)
      reference_sheet = create(:reference_sheet, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')

      expect {
        put :update, params: {
          answers: { "#{element.id}" => 'answer here' },
          reference: { "#{reference_sheet.id}" => {
            relationship: 'roommate',
            title: 'A',
            first_name: 'FN',
            last_name: 'LN',
            phone: 'phone',
            email: 'email@reference.com'
          } },
          id: page.id,
          answer_sheet_id: answer_sheet.id
        }, xhr: true
      }.to have_enqueued_job(Fe::UpdateReferenceSheetVisibilityJob)

      expect(response).to render_template('fe/answer_pages/update')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('answer here')
      expect(reference_sheet.reload.email).to eq('email@reference.com')
    end

    it 'strips whitespace around the reference email' do
      reference_sheet = create(:reference_sheet, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')

      put :update, params: {
        answers: { "#{element.id}" => 'answer here' },
        reference: { "#{reference_sheet.id}" => { email: ' email@reference.com ' } },
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }, xhr: true

      expect(reference_sheet.reload.email).to eq('email@reference.com')
    end

    it 'should store a reference sheet answer' do
      # create a normal applicant sheet to make sure the answer isn't saved to that
      # ref
      ref_page = create(:page, label: 'Ref Page')
      ref_question_sheet = ref_page.question_sheet
      ref_element = create(:text_field_element)
      create(:page_element, element: ref_element, page: ref_page)
      reference_question = create(:reference_question, related_question_sheet_id: ref_question_sheet.id)
      reference_sheet = create(:reference_sheet, question_id: reference_question.id, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')

      put :update, params: {
        answers: { "#{ref_element.id}" => 'ref answer here' },
        id: ref_page.id,
        answer_sheet_id: reference_sheet.id,
        answer_sheet_type: 'Fe::ReferenceSheet'
      }, xhr: true

      expect(response).to render_template('fe/answer_pages/update')
      expect(Fe::Answer.find_by(answer_sheet_id: reference_sheet.id, question_id: ref_element.id).value).to eq('ref answer here')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id)).to be_nil
      # check the associations on reference/answer sheet returns the correct answers
      expect(reference_sheet.reload.answers.collect(&:value)).to eq(['ref answer here'])
      expect(answer_sheet.reload.answers).to eq([])
    end
    context 'when filling out a reference' do
      it 'should not reset the reference even when the email changes' do
        # ref
        ref_page = create(:page, label: 'Ref Page')
        ref_question_sheet = ref_page.question_sheet
        ref_element = create(:text_field_element, object_name: 'answer_sheet', attribute_name: 'email')
        create(:page_element, element: ref_element, page: ref_page)
        reference_question = create(:reference_question, related_question_sheet_id: ref_question_sheet.id)
        reference_sheet = create(:reference_sheet, question_id: reference_question.id, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')
        reference_sheet.generate_access_key
        reference_sheet.save!
        key_before = reference_sheet.access_key

        put :update, params: {
          answers: { "#{ref_element.id}" => 'other@email.com' },
          id: ref_page.id,
          answer_sheet_id: reference_sheet.id,
          answer_sheet_type: 'Fe::ReferenceSheet',
          a: reference_sheet.access_key
        }, xhr: true

        expect(response).to render_template('fe/answer_pages/update')
        reference_sheet.reload
        expect(reference_sheet.email).to eq('other@email.com')
        # make sure the access key isn't reset
        expect(reference_sheet.access_key).to eq(key_before)
      end
    end
  end

  context 'a reference writer with an attachment field, under the README example hook' do
    let(:ref_page) { create(:page) }
    let(:attachment) { create(:attachment_field_element) }
    let(:reference_question) { create(:reference_question, related_question_sheet_id: ref_page.question_sheet.id) }
    let(:reference_sheet) do
      create(:reference_sheet, question_id: reference_question.id, applicant_answer_sheet_id: create(:answer_sheet).id,
                               access_key: 'good-key')
    end
    let(:sheet_params) { {id: ref_page.id, answer_sheet_id: reference_sheet.id, answer_sheet_type: 'Fe::ReferenceSheet'} }

    before do
      create(:page_element, element: attachment, page: ref_page)
      allow(controller).to receive(:fe_can_use_answer_sheet?) do |sheet, _access|
        sheet.is_a?(Fe::ReferenceSheet) && Fe.access_key_matches?(sheet, controller.params[:a])
      end
    end

    # The dummy app has no asset manifest entry for the uploadify files the partial names.
    def without_precompiled_asset_check
      check_precompiled = ActionView::Base.check_precompiled_asset
      ActionView::Base.check_precompiled_asset = false
      yield
    ensure
      ActionView::Base.check_precompiled_asset = check_precompiled
    end

    it 'puts the reference key on the upload and page reload URLs' do
      without_precompiled_asset_check { get :edit, params: sheet_params.merge(a: 'good-key') }

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{/save_file\?[^"]*\ba=good-key})
      expect(response.body).to match(%r{/page/#{ref_page.id}/edit\?[^"]*\ba=good-key})
    end

    it 'lets the writer reach save_file with the key' do
      post :save_file, params: sheet_params.merge(question_id: attachment.id, a: 'good-key'), xhr: true, format: :js

      expect(response).to have_http_status(:ok)
    end

    it 'refuses save_file without the key' do
      post :save_file, params: sheet_params.merge(question_id: attachment.id), xhr: true, format: :js

      expect(response).to have_http_status(:forbidden)
    end

    context 'with a file already attached' do
      # fe leaves file storage to the host app, which defines Fe::Answer#attachment.
      let(:stored_file) do
        '/files/report.pdf'.dup.tap do |file|
          file.define_singleton_method(:attached?) { true }
          file.define_singleton_method(:filename) { 'report.pdf' }
          file.define_singleton_method(:expiring_url) { file }
        end
      end
      let!(:answer) do
        create(:answer, answer_sheet_id: reference_sheet.id, question_id: attachment.id, attachment_file_name: 'report.pdf')
      end

      before { allow_any_instance_of(Fe::Answer).to receive(:attachment).and_return(stored_file) }

      it 'puts the reference key on the delete_file links' do
        without_precompiled_asset_check { get :edit, params: sheet_params.merge(a: 'good-key') }

        expect(response).to have_http_status(:ok)
        delete_urls = response.body.scan(%r{/delete_file\?[^"]*})
        expect(delete_urls).not_to be_empty
        expect(delete_urls).to all(match(/\ba=good-key/))
        expect(delete_urls).to all(match(/\banswer_sheet_type=Fe%3A%3AReferenceSheet\b/))
      end

      it 'deletes the file with the key and keeps the key on the delete link it sends back' do
        delete :delete_file, params: sheet_params.merge(question_id: attachment.id, a: 'good-key'), xhr: true, format: :js

        expect(response).to have_http_status(:ok)
        expect(Fe::Answer.exists?(answer.id)).to be false
        expect(response.body).to match(%r{/delete_file\?[^"]*\ba=good-key})
        expect(response.body).to match(%r{/delete_file\?[^"]*\banswer_sheet_type=Fe%3A%3AReferenceSheet\b})
      end

      it 'refuses delete_file without the key and keeps the file' do
        delete :delete_file, params: sheet_params.merge(question_id: attachment.id), xhr: true, format: :js

        expect(response).to have_http_status(:forbidden)
        expect(Fe::Answer.exists?(answer.id)).to be true
      end
    end
  end
end
