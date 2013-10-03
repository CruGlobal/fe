require "qe/engine"

module Qe
  # prefix for database tables
  mattr_accessor :table_name_prefix
  self.table_name_prefix ||= 'qe_'
  
  mattr_accessor :answer_sheet_class
  self.answer_sheet_class ||='AnswerSheet'
  
  def self.next_label(prefix, labels)
    max = labels.inject(0) do |m, label|
      num = label[/^#{prefix} ([0-9]+)$/i, 1].to_i   # extract your digits
      num > m ? num : m
    end

    "#{prefix} #{max.next}"
  end
end
