require 'rails_helper'

describe Fe do
  describe '.allowed_answer_sheet_types' do
    after { Fe.answer_sheet_types = nil }

    it 'defaults to the answer sheet class and reference sheet' do
      expect(Fe.allowed_answer_sheet_types).to eq(['Fe::Application', 'Fe::ReferenceSheet'])
    end

    it 'uses answer_sheet_types when set' do
      Fe.answer_sheet_types = ['Foo']
      expect(Fe.allowed_answer_sheet_types).to eq(['Foo'])
    end
  end

  describe '.answer_sheet_class_for' do
    it 'returns the default answer sheet class for a blank name' do
      expect(Fe.answer_sheet_class_for(nil)).to eq(Fe::Application)
      expect(Fe.answer_sheet_class_for('')).to eq(Fe::Application)
    end

    it 'returns an allowed class' do
      expect(Fe.answer_sheet_class_for('Fe::ReferenceSheet')).to eq(Fe::ReferenceSheet)
    end

    ['Kernel', 'Fe::Element', '::Fe::Application', ' Fe::Application', 'fe::application'].each do |name|
      it "rejects #{name.inspect}" do
        expect { Fe.answer_sheet_class_for(name) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.element_class_for' do
    it 'returns an allowed class' do
      expect(Fe.element_class_for('Fe::TextField')).to eq(Fe::TextField)
    end

    ['Fe::Question', 'Fe::Application', 'Kernel'].each do |name|
      it "rejects #{name.inspect}" do
        expect { Fe.element_class_for(name) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.access_key_matches?' do
    let(:sheet) { build(:reference_sheet, access_key: 'abc123') }

    it 'is true for the sheet key' do
      expect(Fe.access_key_matches?(sheet, 'abc123')).to be true
    end

    ['wrong', nil, '', ['abc123'], { 'abc123' => 'v' }].each do |key|
      it "is false for #{key.inspect}" do
        expect(Fe.access_key_matches?(sheet, key)).to be false
      end
    end

    it 'is false when the sheet has no access key' do
      sheet.access_key = nil
      expect(Fe.access_key_matches?(sheet, 'abc123')).to be false
      sheet.access_key = ''
      expect(Fe.access_key_matches?(sheet, '')).to be false
    end
  end
end
