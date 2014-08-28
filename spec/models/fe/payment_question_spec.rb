require 'rails_helper'

describe Fe::PaymentQuestion do
  before(:all) do
    @person = create(:fe_person)
    @application = create(:application, applicant: @person)
    @payment_question = Fe::PaymentQuestion.new
  end

  describe "when calling 'response' function" do
    it 'returns a new payment if no application specified' do
      response = @payment_question.send(:response)
      expect(response.new_record?).to be_truthy
    end
    it 'returns the existing application payment if the application already have payments' do
      payment = create(:payment, application: @application)
      response = @payment_question.send(:response, @application).first
      expect(response.id).to be payment.id
    end
    it 'returns a new application payment if the application do not have payments yet' do
      response = @payment_question.send(:response, @application)
      expect(response).not_to be nil
    end
  end

  describe "when calling 'display_response' function" do
    it 'returns a blank string if no application specified' do
      expect(@payment_question).to receive(:response)
      response = @payment_question.send(:display_response)
      expect(response).to eq('')
    end
    it 'returns an existing application payment string if the application already have payments' do
      payment = create(:payment, application: @application)
      expect(@payment_question).to receive(:response).with(@application).and_return(payment)
      response = @payment_question.send(:display_response, @application)
      expect(response).not_to be_blank
    end
    it 'returns a blank string if the application do not have payments yet' do
      expect(@payment_question).to receive(:response).with(@application)
      response = @payment_question.send(:display_response, @application)
      expect(response).to eq('')
    end
  end

  #describe "when calling 'has_response' function" do
    #before(:each) do
      #question_sheet = create(:question_sheet)
      #answer_sheet = create(:answer_sheet)
      #answer_sheet_question_sheet = create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
    #end
    #it "returns a boolean 'false' if no application specified" do
      #response = @payment_question.send(:has_response?)
      #response.should be false
    #end
    #it "returns a boolean 'true' if the application already have payments" do
      #payment = create(:payment, application: @application)
      #response = @payment_question.send(:has_response?, @application)
      #response.should be true
    #end
    #it "returns a boolean 'false' if the application do not have payments yet" do
      #response = @payment_question.send(:has_response?, @application)
      #response.should be false
    #end
  #end
end
