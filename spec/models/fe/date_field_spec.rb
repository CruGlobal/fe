require 'rails_helper'

describe Fe::DateField do
  describe '#ptemplate' do 
    it 'mmyy style' do 
      date_field = Fe::DateField.new
      date_field.style = "mmyy"
      date_field.ptemplate.should == "date_field_mmyy"
    end
    
    it 'default' do 
      date_field = Fe::DateField.new
      date_field.ptemplate.should == "date_field"
    end
  end

  describe '#validation_class' do
    it 'mmyy style' do
      date_field = Fe::DateField.new
      date_field.style = "mmyy"
      date_field.validation_class.should == "validate-selection "
    end

    it 'default' do
      date_field = Fe::DateField.new
      date_field.validation_class.should == "validate-date "
    end
  end

  describe '#response' do
    let(:answer_sheet) { create(:answer_sheet) }
    let(:date_field) { Fe::DateField.create }

    it 'converts db string format to Time' do
      answer = create(:answer, answer_sheet: answer_sheet, question: date_field, value: Time.zone.now)
      date_field.response(answer_sheet).should == Time.parse(answer.reload.value)
    end

    it 'converts US date format format to Time' do
      create(:answer, answer_sheet: answer_sheet, question: date_field, value: '1/12/2013')
      date_field.response(answer_sheet).should == Time.parse('2013-01-12')
    end

    it 'returns empty string if an invalid date is passed in' do
      create(:answer, answer_sheet: answer_sheet, question: date_field, value: '13/12/2013')
      date_field.response(answer_sheet).should == ''
    end
  end
end 
