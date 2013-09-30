require 'qe/engine'

module Qe
	# prefix for database tables
  mattr_accessor :table_name_prefix
  self.table_name_prefix ||= 'qe_'
  
  mattr_accessor :answer_sheet_class
  self.answer_sheet_class ||='Qe::AnswerSheet'
  
  mattr_accessor :from_email
  self.from_email ||= 'info@example.com'
end

require 'qe/model_extensions'
require 'qe/option'
require 'qe/option_group'
require 'qe/page_link'
require 'qe/question_set'

## presenters
# require 'qe/concerns/presenters/presenter'
# require 'qe/concerns/presenters/answer_pages_presenter'
