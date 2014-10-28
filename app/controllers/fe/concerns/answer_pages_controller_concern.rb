module Fe::AnswerPagesControllerConcern
  extend ActiveSupport::Concern

  begin
    included do
      before_filter :get_answer_sheet, :only => [:edit, :update, :save_file, :index]
    end
  rescue ActiveSupport::Concern::MultipleIncludedBlocks
  end

  def edit
    @elements = @presenter.questions_for_page(params[:id]).elements
    @page = Fe::Page.find(params[:id]) || Fe::Page.find_by_number(1)

    render :partial => 'answer_page', :locals => { :show_first => nil }
  end

  # validate and save captured data for a given page
  # PUT /answer_sheets/1/pages/1
  def update
    @page = Fe::Page.find(params[:id])
    questions = @presenter.all_questions_for_page(params[:id])
    questions.post(answer_params, @answer_sheet)

    questions.save

    @elements = questions.elements

    # Save references

    if params[:reference].present?
      params[:reference].keys.each do |id|
        reference_params = params.fetch(:reference)[id].permit(:relationship, :title, :first_name, :last_name, :phone, :email, :is_staff)

        ref = @answer_sheet.reference_sheets.find(id)
        # if the email address has changed, we have to trash the old reference answers
        ref.attributes = reference_params
        ref.save(:validate => false)
      end
    end
    @presenter.active_page = nil
    @answer_sheet.touch
    respond_to do |format|
      format.js
      #format.html
    end
  end

  def save_file
    params.permit(:Filedata)

    if params[:Filedata]
      @page = Fe::Page.find(params[:id])
      @presenter.active_page = @page
      question = Fe::Element.find(params[:question_id])
      answer = Fe::Answer.where(:answer_sheet_id => @answer_sheet.id, :question_id => question.id).first
      question.answers = [answer] if answer

      @answer = question.save_file(@answer_sheet, params[:Filedata])

      render action: :update
    else
      respond_to do |format|
        format.js { head :ok }
      end
    end
  end

  protected

  def get_answer_sheet
    @answer_sheet = answer_sheet_type.find(params[:answer_sheet_id])
    @presenter = Fe::AnswerPagesPresenter.new(self, @answer_sheet, params[:a])
  end

  def answer_sheet_type
    (params[:answer_sheet_type] || Fe.answer_sheet_class || 'AnswerSheet').constantize
  end

  def answer_params
    params.fetch(:answers, {}).permit!
  end
end
