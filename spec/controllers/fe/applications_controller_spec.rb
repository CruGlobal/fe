require 'rails_helper'

class User
  USERS = []

  attr_accessor :person, :id, :username

  def initialize(params)
    USERS << self
    params.each do |k,v|
      self.send("#{k}=", v)
    end
    USERS.collect(&:id).max.to_i + 1
  end

  def self.find(id)
    USERS.detect{ |u| u.id == id }
  end

  def self.clear
    USERS.clear
  end
end

Fe::ApplicationsController.class_eval do
  def current_user
    return User.find session[:user_id]
  end

  def current_person
    current_user.person
  end
end

Fe::Person.class_eval do
  belongs_to :user
  has_many   :applications, class_name: Fe.answer_sheet_class, foreign_key: :applicant_id

  def application
    binding.pry if $a
    applications.first
  end
  def application=(val)
    applications << val unless applications.include?(val)
  end
end

Fe::Application.class_eval do
  belongs_to :applicant, class_name: "Person"
end

describe Fe::ApplicationsController, type: :controller do
  before(:each) do
    Fe::Application.delete_all
    User.clear
    @user = User.new username: 'username'
    @fe_user = Fe::User.where(:user_id => @user.id).first_or_create
    @person = create(:fe_person, user_id: @user.id)
    @user.person = @person
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
      application = Fe::Application.create :applicant_id => @person.id
      @person.application = application
      get :show_default
      expect(assigns(:application)).to_not be_nil
      expect(assigns(:application)).to eq(application)
    end
  end

  context '#create' do
    it 'should work' do
      sheet = Fe::QuestionSheet.create! label: "Question Sheet"
      post :create, question_sheet_id: sheet.id
      expect(assigns(:application)).to_not be_nil
      expect(assigns(:application).question_sheets).to include(sheet)
    end
  end

  context '#edit' do
    it 'should work' do
      session[:user_id] = @user.id
      application = Fe::Application.create :applicant_id => @person.id
      @person.application = application
      get :edit, id: application.id
      expect(assigns(:application))
    end

    it 'should check permissions' do
      session[:user_id] = @user.id
      person2 = create(:fe_person, user_id: @user.id)
      application = Fe::Application.create :applicant_id => person2.id
      get :edit, id: application.id
      expect(response).to redirect_to('http://test.host/')
    end
  end
  
  context '#show' do
    it 'should work' do
      session[:user_id] = @user.id
      application = Fe::Application.create :applicant_id => @person.id
      @person.application = application
      get :show, id: application.id
      expect(assigns(:application))
    end
  end

  context '#no_ref' do
    it 'should work' do
      session[:user_id] = @user.id
      application = Fe::Application.create :applicant_id => @person.id
      @person.application = application
      get :no_ref, id: application.id
      expect(assigns(:application))
    end
  end

  context '#no_conf' do
    it 'should work' do
      session[:user_id] = @user.id
      application = Fe::Application.create :applicant_id => @person.id
      @person.application = application
      get :no_conf, id: application.id
      expect(assigns(:application))
    end
  end

  context '#collated_refs' do
    it 'should work' do
      session[:user_id] = @user.id
      application = Fe::Application.create :applicant_id => @person.id
      @person.application = application
      qs = Fe::QuestionSheet.create id: 2
      get :no_conf, id: application.id
      expect(assigns(:application))
    end
  end
end
