# QuestionSheets is used exclusively on the administration side to design a Questionniare
#  which can than be instantiated as an AnswerSheet for data capture on the front-end
class Fe::Admin::QuestionSheetsController < ApplicationController
  include Fe::Admin::QuestionSheetsControllerConcern
end

