require 'spec_helper'

describe DateField do 
  describe '#ptemplate' do 
    it 'mmyy style' do 
      date_field = DateField.new
      date_field.style = "mmyy"
      date_field.ptemplate.should == "date_field_mmyy"
    end
    
    it 'default' do 
      date_field = DateField.new
      date_field.ptemplate.should == "date_field"
    end
  end
end 
