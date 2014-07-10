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
end
