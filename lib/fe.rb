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

  mattr_accessor :verbose_debugs
  self.verbose_debugs = false

  # Optimistic concurrency: reject saves when the MD5 digest of answers
  # has changed since the page was loaded (another tab/user saved first).
  mattr_accessor :md5_overwrite_protection
  self.md5_overwrite_protection = true

  # Blank-form protection: reject saves that would overwrite non-blank
  # answers with blank/whitespace-only values.
  mattr_accessor :blank_overwrite_protection
  self.blank_overwrite_protection = true

  def self.verbose_debugs?
    !!verbose_debugs
  end
end
