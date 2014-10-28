require 'rails_helper'

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
  
end
