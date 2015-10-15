require 'rails_helper'

describe Fe::Admin::EmailTemplatesController, type: :controller do
  let(:email_template) { create(:email_template) }

  context '#index' do
    it 'should work' do
      email_template = create(:email_template, name: 'Template')
      get :index
      expect(assigns(:email_templates)).to eq([email_template])
    end
  end
  
  context '#new' do
    it 'should work' do
      get :new
      expect(assigns(:email_template)).to_not be_nil
    end
  end

  context '#create' do
    it 'should work' do
      expect {
        post :create, email_template: { name: 'Name', subject: 'Subject', content: 'Content' }
      }.to change{Fe::EmailTemplate.count}.by(1)
      expect(assigns(:email_template)).to_not be_nil
    end
  end
end
