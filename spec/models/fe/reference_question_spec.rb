require 'rails_helper' 

describe Fe::ReferenceQuestion do
  describe '#ptemplate' do 
    it 'default' do 
      ref = create(:reference_question)
      expect(ref.style).to eq("peer")
      expect(ref.ptemplate).to eq("fe/reference_peer")
    end
    
    it 'customized' do 
      ref = create(:reference_question)
      ref.style = "abc"
      expect(ref.ptemplate).to eq("fe/reference_abc")
    end
  end
end
