require "fe/engine"

module Fe
  LANGUAGES = { 'es' => 'Español', 'pt' => 'Português' }
  # prefix for database tables
  mattr_accessor :table_name_prefix
  self.table_name_prefix ||= 'fe_'

  mattr_accessor :answer_sheet_class
  self.answer_sheet_class ||= 'Fe::Application'

  mattr_accessor :from_email
  self.from_email ||= 'info@example.com'

  mattr_accessor :never_reuse_elements
  self.never_reuse_elements = false

  def self.next_label(prefix, labels)
    max = labels.inject(0) do |m, label|
      num = label[/^#{prefix} ([0-9]+)$/i, 1].to_i   # extract your digits
      num > m ? num : m
    end

    "#{prefix} #{max.next}"
  end

  mattr_accessor :date_format
  self.date_format = 'yy-mm-dd'

  mattr_accessor :bootstrap
  self.bootstrap = false
end
