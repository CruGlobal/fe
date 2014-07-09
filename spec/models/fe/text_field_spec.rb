require 'rails_helper'

describe Fe::TextField do
  
  describe '#ptemplate' do 
    it 'default style' do 
      text_field = Fe::TextField.new
      text_field.ptemplate.should == "text_field"
    end
    
    it 'essay style' do 
      text_field = Fe::TextField.new
      text_field.style = "essay"
      text_field.ptemplate.should == "text_area_field"
    end 
  end
end
