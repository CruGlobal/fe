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

  class MissingAccessHook < StandardError; end

  ANSWER_SHEET_CONTROLLERS = %w[
    Fe::AnswerSheetsController Fe::AnswerPagesController Fe::ReferenceSheetsController
    Fe::SubmitPagesController Fe::ReferencePagesController Fe::ReferencesController
  ].freeze

  ADMIN_CONTROLLERS = %w[
    Fe::Admin::QuestionSheetsController Fe::Admin::QuestionPagesController
    Fe::Admin::ElementsController Fe::Admin::EmailTemplatesController
  ].freeze

  mattr_accessor :verify_access_hooks_on_boot
  self.verify_access_hooks_on_boot = true

  # Raises Fe::MissingAccessHook unless the host app defines the access hooks
  # on every fe controller that calls them. fe must never define either hook
  # itself, or this check could not detect a missing host implementation.
  def self.verify_access_hooks!
    missing = {
      fe_can_use_answer_sheet?: ANSWER_SHEET_CONTROLLERS,
      fe_admin?: ADMIN_CONTROLLERS
    }.flat_map do |hook, names|
      names.map(&:constantize).reject { |klass|
        klass.method_defined?(hook) || klass.private_method_defined?(hook)
      }.map { |klass| [hook, klass.name] }
    end
    return if missing.empty?

    lines = missing.map { |hook, name| "  #{name} needs ##{hook}" }
    raise MissingAccessHook,
      "The host app must define fe's access hooks, and these are missing:\n#{lines.join("\n")}\n" \
      'See the "Access control" section of the fe README.'
  end
end
