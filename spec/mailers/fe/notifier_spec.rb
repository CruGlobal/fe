require 'rails_helper'
 
RSpec.describe Fe::Notifier do
  describe 'instructions' do
    let(:user) { mock_model User, name: 'Lucas', email: 'lucas@email.com' }
    let(:mail) { Fe::Notifier.notification('recipient@test.com', 'from@test.com', 'Staff Payment Request', {}, {format: 'html'}) }
 
    before(:each) do
      create(:fe_email_template, name: 'Staff Payment Request', subject: 'Staff Payment Request Subject', content: "<a href='test'>test</a>")
    end

    it 'renders the subject' do
      expect(mail.subject).to eql('Staff Payment Request Subject')
    end
 
    it 'renders the receiver email' do
      expect(mail.to).to eql(['recipient@test.com'])
    end
 
    it 'renders the sender email' do
      expect(mail.from).to eql(['from@test.com'])
    end
 
    it 'sets the email to be an html email when format passed in is html' do
      mail = Fe::Notifier.notification('recipient@test.com', 'from@test.com', 'Staff Payment Request', {}, {format: 'html'})
      expect(mail[:content_type].to_s).to match(/text\/html/)
    end

    it 'sets the email to be a text email when text format is passed in' do
      mail = Fe::Notifier.notification('recipient@test.com', 'from@test.com', 'Staff Payment Request', {}, {format: 'text'})
      expect(mail[:content_type].to_s).to match(/text\/plain/)
    end

    it 'sets the email to be a text email when no format passed in' do
      mail = Fe::Notifier.notification('recipient@test.com', 'from@test.com', 'Staff Payment Request', {}, {})
      expect(mail[:content_type].to_s).to match(/text\/plain/)
    end
  end
end
