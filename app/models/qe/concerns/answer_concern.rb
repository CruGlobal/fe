module AnswerConcern
  extend ActiveSupport::Concern
  include ActionView::Helpers::TextHelper

  included do

    belongs_to :answer_sheet
    belongs_to :question, :class_name => "Element", :foreign_key => "question_id"

  #  validates_presence_of :value
    validates_length_of :short_value, :maximum => 255, :allow_nil => true

    before_save :set_value_from_filename
  end

  def set(value, short_value = value)
    self.value = value
    self.short_value = truncate(short_value, :length => 225) # adds ... if truncated (but not if not)
  end

  def to_s
    self.value
  end

  def set_value_from_filename
    self.value = self.short_value = self.attachment_file_name if self[:attachment_file_name].present?
  end

  module ClassMethods
    def table_name
      "#{Qe.table_name_prefix}answers"
    end
  end
end