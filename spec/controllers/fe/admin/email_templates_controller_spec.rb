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
        post :create, params: {email_template: { name: 'Name', subject: 'Subject', content: 'Content' }}
      }.to change{Fe::EmailTemplate.count}.by(1)
      expect(assigns(:email_template)).to_not be_nil
    end
  end
end

describe Fe::Admin::EmailTemplatesController, type: :controller do
  it 'returns 403 on #index when the host says the person is not an admin' do
    allow(controller).to receive(:fe_admin?).and_return(false)
    get :index
    expect(response).to have_http_status(:forbidden)
  end
end
