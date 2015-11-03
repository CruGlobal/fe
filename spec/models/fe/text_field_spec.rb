require 'rails_helper'

describe Fe::TextField do
  
  describe '#ptemplate' do 
    it 'default style' do 
      text_field = Fe::TextField.new
      expect(text_field.ptemplate).to eq("fe/text_field")
    end
    
    it 'essay style' do 
      text_field = Fe::TextField.new
      text_field.style = "essay"
      expect(text_field.ptemplate).to eq("fe/text_area_field")
    end 
  end

  it 'should match conditional_match' do
    qs = create(:question_sheet)
    app = create(:application)
    app.question_sheets << qs
    e = create(:text_field_element, conditional_answer: 'a;b', style: 'drop-down')
    qs.pages << create(:page)
    qs.pages.reload.first.elements << e
    a = create(:answer, question_id: e.id, value: 'b', answer_sheet_id: app.id)
    expect(e.conditional_match(app)).to be true
  end

  it "should not match conditional_match if the answer doesn't match" do
    qs = create(:question_sheet)
    app = create(:application)
    app.question_sheets << qs
    e = create(:text_field_element, conditional_answer: 'a;b', style: 'drop-down')
    qs.pages << create(:page)
    qs.pages.reload.first.elements << e
    a = create(:answer, question_id: e.id, value: 'c', answer_sheet_id: app.id)
    expect(e.conditional_match(app)).to_not be true
  end
end
