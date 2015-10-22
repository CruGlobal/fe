require 'rails_helper'
require 'rexml/document'

describe Fe::ChoiceField do
  
  describe "when calling 'ptemplate' function" do
    it 'returns a nil if style is nil' do
      expect(Fe::ChoiceField.new().ptemplate).to be_nil
    end
    it 'returns a checkbox_field type' do
      expect(Fe::ChoiceField.new(style: 'checkbox').ptemplate).to eq 'fe/checkbox_field'
    end
    it 'returns a drop_down_field type' do
      expect(Fe::ChoiceField.new(style: 'drop-down').ptemplate).to eq 'fe/drop_down_field'
    end
    it 'returns a radio_button_field type' do
      expect(Fe::ChoiceField.new(style: 'radio').ptemplate).to eq 'fe/radio_button_field'
    end
    it 'returns a yes_no type' do
      expect(Fe::ChoiceField.new(style: 'yes-no').ptemplate).to eq 'fe/yes_no'
    end
    it 'returns a rating type' do
      expect(Fe::ChoiceField.new(style: 'rating').ptemplate).to eq 'fe/rating'
    end
    it 'returns a acceptance type' do
      expect(Fe::ChoiceField.new(style: 'acceptance').ptemplate).to eq 'fe/acceptance'
    end
    it 'returns a country type' do
      expect(Fe::ChoiceField.new(style: 'country').ptemplate).to eq 'fe/country'
    end
  end
  
  context '#choices' do
    it 'should work for yes-no style' do
      expect(Fe::ChoiceField.new(style: 'yes-no').choices).to eq([["Yes",1],["No",0]])
    end
    it 'should work for acceptance style' do
      expect(Fe::ChoiceField.new(style: 'acceptance').choices).to eq([["Yes",1],["No",0]])
    end
    it 'should work for a local source using libxml' do
      expect(Fe::ChoiceField.new(style: 'drop-down', source: 'spec/support/choices.xml', text_xpath: 'choice', value_xpath: 'value').choices).to eq([["A","1"],["B","0"]])
    end
    if RUBY_VERSION =~ /^2/
      it 'should work for a remote source using rexml' do
        expect(Fe::ChoiceField.new(style: 'drop-down', source: 'https://raw.githubusercontent.com/CruGlobal/fe/master/spec/support/choices.xml', text_xpath: '*/choice', value_xpath: '*/value').choices).to eq([["A","1"],["B","0"]])
      end
    end
    it 'should work for content set' do
      expect(Fe::ChoiceField.new(style: 'drop-down', content: "1;A\n0;B").choices).to eq([["A","1"],["B","0"]])
    end
  end

  context '#conditional_match' do
    it 'returns true if any of the options are selected' do
      app = create(:application)
      e = create(:choice_field_element, conditional_answer: 'a;b')
      a = create(:answer, question_id: e, value: 'a;b;c')
      expect(e.conditional_match).to be true
    end
  end
end
