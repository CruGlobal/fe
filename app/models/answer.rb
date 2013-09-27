# Answer
# - a single answer to a given question for a specific answer sheet (instance of capturing answers)
# - there may be multiple answers to a question for "choose many" (checkboxes)

# short value is indexed for finding the value (reporting)
# essay questions have a nil short value
# may want special handling for ChoiceFields to store both id/slug and text representations

class Answer < ActiveRecord::Base
  include AnswerConcern
end
