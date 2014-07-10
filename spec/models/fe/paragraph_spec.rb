require 'rails_helper'

describe Fe::Paragraph do
  describe '#validate_presence_of :content on update' do 
    it 'successfully saves with content' do 
      paragraph = build(:paragraph)
      paragraph.content = "abc"
      expect(paragraph.save).to eq(true)
    end
    
    it 'saves with default content' do 
      paragraph = build(:paragraph) 
      expect(paragraph.save).to eq(true)
      expect(paragraph.content).to eq("Lorem ipsum...")
    end
  end
end
