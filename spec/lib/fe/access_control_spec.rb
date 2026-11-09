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

  describe '.verify_access_hooks!' do
    let(:answer_hook) { :fe_can_use_answer_sheet? }

    def stub_lists(answer: [], admin: [])
      stub_const('Fe::ANSWER_SHEET_CONTROLLERS', answer)
      stub_const('Fe::ADMIN_CONTROLLERS', admin)
    end

    it 'passes for the dummy app with the real lists' do
      expect(Fe.verify_access_hooks!).to be_nil
    end

    it 'raises when an answer sheet controller has no hook' do
      stub_const('FeNoHooksController', Class.new)
      stub_lists(answer: %w[FeNoHooksController])

      expect { Fe.verify_access_hooks! }.to raise_error(Fe::MissingAccessHook) { |e|
        expect(e.message).to include('fe_can_use_answer_sheet?', 'FeNoHooksController', 'Access control')
      }
    end

    it 'raises when an admin controller has no fe_admin?' do
      stub_const('FeNoAdminController', Class.new)
      stub_lists(admin: %w[FeNoAdminController])

      expect { Fe.verify_access_hooks! }.to raise_error(Fe::MissingAccessHook) { |e|
        expect(e.message).to include('fe_admin?', 'FeNoAdminController')
      }
    end

    it 'requires fe_admin? on the answer sheets controller' do
      klass = Class.new do
        protected

        def fe_can_use_answer_sheet?(*) = true
      end
      stub_const('Fe::AnswerSheetsController', klass)
      stub_lists(answer: %w[Fe::AnswerSheetsController])

      expect { Fe.verify_access_hooks! }.to raise_error(Fe::MissingAccessHook) { |e|
        expect(e.message).to include('fe_admin?', 'Fe::AnswerSheetsController')
        expect(e.message).not_to include('fe_can_use_answer_sheet?')
      }
    end

    it 'names every missing method and class in one error' do
      stub_const('FeNoHooksController', Class.new)
      stub_const('FeNoAdminController', Class.new)
      stub_lists(answer: %w[FeNoHooksController], admin: %w[FeNoAdminController])

      expect { Fe.verify_access_hooks! }.to raise_error(Fe::MissingAccessHook) { |e|
        expect(e.message).to include('fe_can_use_answer_sheet?', 'FeNoHooksController', 'fe_admin?', 'FeNoAdminController')
      }
    end

    it 'passes when both hooks are inherited from a parent' do
      parent = Class.new do
        protected

        def fe_can_use_answer_sheet?(*) = true
        def fe_admin? = true
      end
      stub_const('FeChildAnswerController', Class.new(parent))
      stub_const('FeChildAdminController', Class.new(parent))
      stub_lists(answer: %w[FeChildAnswerController], admin: %w[FeChildAdminController])

      expect(Fe.verify_access_hooks!).to be_nil
    end

    it 'passes when the hook comes from a prepended module' do
      mod = Module.new do
        def fe_can_use_answer_sheet?(*) = true
      end
      klass = Class.new
      klass.prepend(mod)
      stub_const('FePrependedController', klass)
      stub_lists(answer: %w[FePrependedController])

      expect(Fe.verify_access_hooks!).to be_nil
    end

    it 'passes when the hook is a protected method on the class itself' do
      klass = Class.new do
        protected

        def fe_admin? = true
      end
      stub_const('FeProtectedController', klass)
      stub_lists(admin: %w[FeProtectedController])

      expect(Fe.verify_access_hooks!).to be_nil
    end
  end
end
