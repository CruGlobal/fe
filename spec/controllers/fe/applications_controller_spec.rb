require 'rails_helper'

::Application.const_set('YEAR', 2015)

describe Fe::ApplicationsController, type: :controller do
  before(:all) do
    Fe.answer_sheet_class = '::Application'
  end

  after(:all) do
    Fe.answer_sheet_class = 'Fe::Application'
  end

  before(:each) do
    ::Application.delete_all
    @user = create(:dummy_user, username: 'username')
    @fe_user = create(:fe_user, user: @user)
    @person = create(:dummy_person, user_id: @user.id)
  end

  context '#index' do
    it 'should work' do
      session[:user_id] = @user.id
      get :index
      expect(response).to redirect_to('/fe/applications/show_default')
    end
  end

  context '#show_default' do
    it 'should work with no application created yet' do
      session[:user_id] = @user.id
      get :show_default
      expect(assigns(:application)).to_not be_nil
    end
    it 'should work with an application already created' do
      session[:user_id] = @user.id
      application = ::Application.create :applicant_id => @person.id
      @person.application = application
      get :show_default
      expect(assigns(:application)).to_not be_nil
      expect(assigns(:application)).to eq(application)
    end
  end

  context '#create' do
    it 'should work' do
      session[:user_id] = @user.id
      sheet = Fe::QuestionSheet.create! label: "Question Sheet"
      post :create, question_sheet_id: sheet.id
      expect(assigns(:application)).to_not be_nil
      expect(assigns(:application).question_sheets).to include(sheet)
    end
  end

  context '#edit' do
    it 'should work' do
      session[:user_id] = @user.id
      application = ::Application.create :applicant_id => @person.id
      @person.application = application
      get :edit, id: application.id
      expect(assigns(:application))
      expect(response).to render_template('fe/answer_sheets/edit')
    end

    it 'should check permissions' do
      session[:user_id] = @user.id
      person2 = create(:fe_person, user_id: @user.id)
      application = ::Application.create :applicant_id => person2.id
      get :edit, id: application.id
      expect(response).to redirect_to('http://test.host/')
    end
  end
  
  context '#show' do
    it 'should work' do
      session[:user_id] = @user.id
      application = ::Application.create :applicant_id => @person.id
      @person.application = application
      get :show, id: application.id
      expect(assigns(:application))
    end
  end

  context '#no_ref' do
    it 'should work' do
      session[:user_id] = @user.id
      application = ::Application.create :applicant_id => @person.id
      @person.application = application
      get :no_ref, id: application.id
      expect(assigns(:application))
    end
  end

  context '#no_conf' do
    it 'should work' do
      session[:user_id] = @user.id
      application = ::Application.create :applicant_id => @person.id
      @person.application = application
      get :no_conf, id: application.id
      expect(assigns(:application))
    end
  end

  context '#get_year' do
    it 'should work' do
      controller.get_year_tester
    end
  end
end
