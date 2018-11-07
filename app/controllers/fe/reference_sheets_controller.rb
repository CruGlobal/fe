# TODO determine how this relates to Fe::ReferencesController and if we can delete one of the two
class Fe::ReferenceSheetsController < Fe::AnswerSheetsController
  #skip_before_action :ssm_login_required, :login
  before_action :edit_only, :except => [:edit]

  def edit
    @reference_sheet = @answer_sheet
    unless @answer_sheet
      render :not_found and return
    end
    @answer_sheet.start! if @answer_sheet.created?
    # Set up question_sheet if needed
    if @answer_sheet.question_sheets.empty?
      @answer_sheet.question_sheets << Fe::QuestionSheet.find(@answer_sheet.question.related_question_sheet)
    end
    @presenter = Fe::AnswerPagesPresenter.new(self, @answer_sheet, params[:a])
    @elements = @presenter.questions_for_page(:first).elements
    @page = @presenter.pages.first
    render 'fe/answer_sheets/edit', layout: 'fe/application'
  end

  protected
    def get_answer_sheet
      @answer_sheet ||= Fe::ReferenceSheet.find_by_id_and_access_key(params[:id], params[:a])
      return false unless @answer_sheet
    end

    def edit_only
      return false
    end
end
