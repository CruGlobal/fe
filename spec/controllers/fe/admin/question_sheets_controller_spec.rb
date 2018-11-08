require 'rails_helper'

describe Fe::Admin::QuestionSheetsController, type: :controller do
  context '#index' do
    it 'should work' do
      active_qs = create(:question_sheet, archived: false)
      archived_qs = create(:question_sheet, archived: true)
      get :index
      expect(assigns(:active_question_sheets)).to_not be_nil
      expect(assigns(:archived_question_sheets)).to_not be_nil
      expect(assigns(:active_question_sheets)).to eq([active_qs])
      expect(assigns(:archived_question_sheets)).to eq([archived_qs])
    end
  end
  context '#archive' do
    it 'should work' do
      active_qs = create(:question_sheet, archived: false)
      request.env["HTTP_REFERER"] = '/'
      post :archive, params: {id: active_qs.id}
      expect(active_qs.reload.archived).to be true
    end
  end
  context '#unarchive' do
    it 'should work' do
      active_qs = create(:question_sheet, archived: true)
      request.env["HTTP_REFERER"] = '/'
      post :unarchive, params: {id: active_qs.id}
      expect(active_qs.reload.archived).to be false
    end
  end
  context '#duplicate' do
    it 'should work' do
      qs = create(:question_sheet)
      request.env["HTTP_REFERER"] = '/'
      expect {
        post :duplicate, params: {id: qs.id}
      }.to change{Fe::QuestionSheet.count}.by(1)
      expect(Fe::QuestionSheet.last.label).to eq("#{qs.label} - COPY")
    end
  end
  context '#show' do
    it 'should work' do
      qs = create(:question_sheet)
      p1 = create(:page, question_sheet: qs)
      p2 = create(:page, question_sheet: qs)
      get :show, params: {id: qs.id}
      expect(assigns(:all_pages)).to eq([p1, p2])
      expect(assigns(:page)).to eq(p1)
    end
  end
end
