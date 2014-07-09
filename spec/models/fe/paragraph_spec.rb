require 'rails_helper'

describe Fe::Paragraph do
  describe '#validate_presence_of :content on update' do 
    it 'successfully saves with content' do 
      paragraph = build(:paragraph)
      paragraph.content = "abc"
      paragraph.save.should be_true 
    end
    
    it 'saves with default content' do 
      paragraph = build(:paragraph) 
      paragraph.save.should be_true
      paragraph.content.should == "Lorem ipsum..."
    end
  end
end
