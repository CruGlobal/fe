require 'rails_helper' 

describe Fe::ReferenceQuestion do
  describe '#ptemplate' do 
    it 'default' do 
      ref = create(:reference_question)
      ref.style.should == "peer"
      ref.ptemplate.should == "reference_peer"
    end
    
    it 'customized' do 
      ref = create(:reference_question)
      ref.style = "abc"
      ref.ptemplate.should == "reference_abc"
    end
  end
end
