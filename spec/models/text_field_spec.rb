require 'spec_helper'

describe TextField do 
  
  describe '#ptemplate' do 
    it 'default style' do 
      text_field = TextField.new
      text_field.ptemplate.should == "text_field"
    end
    
    it 'essay style' do 
      text_field = TextField.new
      text_field.style = "essay"
      text_field.ptemplate.should == "text_area_field"
    end 
  end
end
