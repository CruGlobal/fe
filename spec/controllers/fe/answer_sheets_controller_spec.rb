require 'rails_helper'

describe Fe::AnswerSheetsController, type: :controller do
  let(:question_sheet) { create(:question_sheet) }
  let(:answer_sheet) { create(:answer_sheet, applicant_id: create(:fe_person).id) }

  context 'access control' do
    before do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      create(:page, question_sheet: question_sheet)
    end

    it 'asks the host for :look on show' do
      expect(controller).to receive(:fe_can_use_answer_sheet?).with(answer_sheet, :look).and_return(true)
      get :show, params: {id: answer_sheet.id}
    end
    it 'asks the host for :change on edit' do
      expect(controller).to receive(:fe_can_use_answer_sheet?).with(answer_sheet, :change).and_return(true)
      get :edit, params: {id: answer_sheet.id}
    end
    context 'when the host refuses' do
      before { allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(false) }

      it 'returns 403 without running the action' do
        get :edit, params: {id: answer_sheet.id}
        expect(response).to have_http_status(:forbidden)
        expect(assigns(:presenter)).to be_nil
      end
      it 'lets fe_access_denied redirect' do
        expect(controller).to receive(:fe_access_denied).with(:answer_sheet) { controller.redirect_to '/denied' }
        get :edit, params: {id: answer_sheet.id}
        expect(response).to redirect_to('/denied')
      end
      it 'returns 403 when fe_access_denied renders nothing' do
        allow(controller).to receive(:fe_access_denied)
        get :edit, params: {id: answer_sheet.id}
        expect(response).to have_http_status(:forbidden)
      end
    end
    it 'propagates exceptions from the host hook' do
      allow(controller).to receive(:fe_can_use_answer_sheet?).and_raise(RuntimeError, 'nope')
      expect { get :edit, params: {id: answer_sheet.id} }.to raise_error(RuntimeError, 'nope')
    end
    it 'returns 403 when the host defines no hook' do
      allow(controller).to receive(:respond_to?).and_call_original
      allow(controller).to receive(:respond_to?).with(:fe_can_use_answer_sheet?, true).and_return(false)
      get :edit, params: {id: answer_sheet.id}
      expect(response).to have_http_status(:forbidden)
    end

    context 'when a subclass re-declares before_action :get_answer_sheet' do
      controller(Fe::AnswerSheetsController) { before_action :get_answer_sheet }

      it 'still asks the host and returns 403 on edit' do
        filters = controller.class._process_action_callbacks.map(&:filter)
        expect(filters.index(:get_answer_sheet)).to be > filters.index(:fe_authorize_answer_sheet!)
        expect(controller).to receive(:fe_can_use_answer_sheet?).with(answer_sheet, :change).and_return(false)

        get :edit, params: {id: answer_sheet.id}

        expect(response).to have_http_status(:forbidden)
        expect(assigns(:presenter)).to be_nil
      end
    end

    context 'when a re-declared loader redirects' do
      controller(Fe::AnswerSheetsController) do
        before_action :get_answer_sheet

        def get_answer_sheet
          redirect_to '/elsewhere'
        end
      end

      it 'stops the request without asking the host' do
        expect(controller).not_to receive(:fe_can_use_answer_sheet?)

        get :edit, params: {id: answer_sheet.id}

        expect(response).to redirect_to('/elsewhere')
      end
    end
  end
  context 'when the person is not an admin' do
    before { allow(controller).to receive(:fe_admin?).and_return(false) }

    it 'returns 403 on index' do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 on create and makes no answer sheet' do
      question_sheet
      expect { post :create, params: {question_sheet_id: question_sheet.id} }
        .not_to change { Fe.answer_sheet_class.constantize.count }
      expect(response).to have_http_status(:forbidden)
    end

    context 'with a subclass that defines its own create' do
      controller(Fe::AnswerSheetsController) do
        def create
          head :ok
        end
      end

      it 'leaves the host action alone' do
        post :create, params: {question_sheet_id: question_sheet.id}
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with a subclass that inherits create' do
      controller(Fe::AnswerSheetsController) {}

      it 'returns 403' do
        post :create, params: {question_sheet_id: question_sheet.id}
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  context '#index' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)

      get :index
      expect(assigns(:answer_sheets).to_a).to eq([answer_sheet])
    end
  end
  context '#create' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)

      post :create, params: {question_sheet_id: question_sheet.id}
      expect(assigns(:answer_sheet)).to_not be_nil
    end
  end
  context '#edit' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      page = create(:page, question_sheet: question_sheet)

      get :edit, params: {id: answer_sheet.id}
      expect(assigns(:elements)).to eq([])
      expect(assigns(:page)).to eq(page)
    end
    it 'adds the initial answers digest script without calling jQuery first' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      create(:page, question_sheet: question_sheet)

      get :edit, params: {id: answer_sheet.id}

      script = response.body[%r{<script>[^<]*answers_digest[^<]*</script>}]
      expect(script).to include(assigns(:answers_digest))
      expect(script).not_to match(/<script>\s*\$/)
    end
    it 'stores the initial answers digest whether jQuery and fe load before or after the script' do
      skip 'node is not installed' unless system('node', '-v', out: File::NULL, err: File::NULL)
      allow(Fe).to receive(:verbose_js_logging?).and_return(true)
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      create(:page, question_sheet: question_sheet)

      get :edit, params: {id: answer_sheet.id}

      script = response.body[%r{<script>([^<]*answers_digest[^<]*)</script>}, 1]
      harness = <<~JS
        const vm = require('vm');
        // Runs the script with the page in readyState, jQuery loaded before or after it, and fe present or not.
        const run = (readyState, jqueryFirst, withFe) => {
          const stored = {}, listeners = [];
          const ctx = { document: { readyState, addEventListener: (event, fn) => { if (event === 'DOMContentLoaded') listeners.push(fn); } } };
          const jQuery = (arg) => {
            if (typeof arg !== 'function') return { data: (key, value) => { stored[key] = value; } };
            if (readyState === 'loading') listeners.push(arg); else arg();
          };
          ctx.window = ctx;
          const load = () => { ctx.jQuery = jQuery; if (withFe) ctx.fe = { debugLog() {} }; };
          if (jqueryFirst) load();
          vm.runInNewContext(#{script.to_json}, ctx);
          if (!jqueryFirst) load();
          listeners.forEach((fn) => fn());
          return stored.answers_digest || null;
        };
        console.log(JSON.stringify([run('loading', false, true), run('loading', true, true), run('complete', true, true), run('complete', true, false)]));
      JS

      output = IO.popen(['node', '-e', harness], &:read)
      expect(JSON.parse(output)).to eq([assigns(:answers_digest)] * 4)
    end
    context 'when the question_sheet is blank' do
      context 'when referrer is available' do
        it 'should redirect to referrer' do
          create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
          request.env['HTTP_REFERER'] = '/referrer'

          get :edit, params: {id: answer_sheet.id}
          expect(response).to redirect_to('http://test.host/referrer')
        end
      end
      context 'when referrer is not available' do
        it 'should render an empty page with a flash message' do
          create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)

          get :edit, params: {id: answer_sheet.id}
          expect(response.body['Sorry, there are no questions for this form yet.']).to_not be_nil
        end
      end
    end
  end
  context '#show' do
    let(:page) { create(:page, question_sheet: question_sheet) }
    let(:el_confidential) { create(:text_field_element, is_confidential: true) }
    let(:el_visible) { create(:text_field_element, is_confidential: false) }

    before do
      answer_sheet.question_sheets << question_sheet
    end

    it 'should work' do
      text_field = create(:text_field_element)
      page.elements << text_field

      get :show, params: {id: answer_sheet.id}
      expect(assigns(:elements)).to eq(page => [text_field])
    end
    context 'filtering' do
      let(:el_confidential) { create(:text_field_element, is_confidential: true) }
      let(:el_visible) { create(:text_field_element, is_confidential: false) }
      let(:el_visible2) { create(:text_field_element, is_confidential: false) }

      before do
        page.elements << el_confidential << el_visible << el_visible2
      end

      it 'should filter out elements' do
        allow_any_instance_of(Fe::AnswerSheetsController).to receive(:get_filter).and_return(filter_default: :show, filter: [ :is_confidential ])

        get :show, params: {id: answer_sheet.id}
        expect(assigns(:elements)).to eq(page => [el_visible, el_visible2])
      end
      it 'should filter in elements' do
        allow_any_instance_of(Fe::AnswerSheetsController).to receive(:get_filter).and_return(filter_default: :hide, filter: [ :is_confidential ])

        get :show, params: {id: answer_sheet.id}
        expect(assigns(:elements)).to eq(page => [el_confidential])
      end
    end
    context 'element on multiple pages' do
      let!(:question_sheet2) { create(:question_sheet) }
      let!(:page2) { create(:page, question_sheet: question_sheet2) }

      it 'should pull the right page' do
        text_field = create(:text_field_element)
        page.elements << text_field
        page2.elements << text_field

        get :show, params: {id: answer_sheet.id}
        expect(assigns(:elements)).to eq(page => [text_field])
      end
    end
  end
  context '#send_reference_invite' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      page = create(:page, question_sheet: question_sheet)
      ref_question = create(:reference_element)
      create(:page_element, element: ref_question, page: page)
      ref_sheet = create(:reference_sheet, applicant_answer_sheet: answer_sheet, question: ref_question)
      create(:email_template, name: 'Reference Invite')
      create(:email_template, name: 'Reference Notification to Applicant')

      post :send_reference_invite, params: {
        reference: {
           ref_sheet.id.to_s => {
              relationship: 'rel', title: 'title', first_name: 'first_name',
              last_name: 'last_name', phone: 'phone', email: 'email@email.com' }
            },
            reference_id: ref_sheet.id, id: answer_sheet.id
        }, xhr: true
      ref_sheet.reload
      expect(ref_sheet.relationship).to eq('rel')
      expect(ref_sheet.title).to eq('title')
      expect(ref_sheet.first_name).to eq('first_name')
      expect(ref_sheet.last_name).to eq('last_name')
      expect(ref_sheet.phone).to eq('phone')
      expect(ref_sheet.email).to eq('email@email.com')
    end
  end
  context '#pages' do
    it 'filters out hidden pages' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      page = create(:page, question_sheet: question_sheet)
      page2 = create(:page, question_sheet: question_sheet, hidden: true)
      expect(answer_sheet.pages).to eq([page])
    end
  end
end
