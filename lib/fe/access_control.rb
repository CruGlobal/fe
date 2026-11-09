module Fe
  # Class names accepted from request params for answer sheets. Defaults to
  # the answer sheet class plus Fe::ReferenceSheet.
  mattr_accessor :answer_sheet_types
  self.answer_sheet_types = nil

  mattr_accessor :element_types
  self.element_types = %w[
    Fe::Section Fe::Paragraph Fe::TextField Fe::ChoiceField Fe::DateField
    Fe::QuestionGrid Fe::QuestionGridWithTotal Fe::AttachmentField
    Fe::ReferenceQuestion Fe::StateChooser
  ]

  def self.allowed_answer_sheet_types
    answer_sheet_types || [answer_sheet_class, 'Fe::ReferenceSheet']
  end

  def self.answer_sheet_class_for(name)
    return answer_sheet_class.constantize if name.blank?
    raise ActiveRecord::RecordNotFound unless allowed_answer_sheet_types.include?(name)
    name.constantize
  end

  def self.element_class_for(name)
    raise ActiveRecord::RecordNotFound unless element_types.include?(name)
    name.constantize
  end

  def self.access_key_matches?(answer_sheet, key)
    return false unless key.is_a?(String) && !key.empty?
    expected = answer_sheet.access_key
    return false if expected.blank?
    ActiveSupport::SecurityUtils.secure_compare(expected, key)
  end
end
