module Fe::AnswerSheetsControllerConcern
  extend ActiveSupport::Concern

  begin
    included do
      layout 'fe/application'
      before_action :get_answer_sheet, :only => [:edit, :show, :send_reference_invite, :submit]
    end
  rescue ActiveSupport::Concern::MultipleIncludedBlocks
  end

  # list existing answer sheets
  def index

    @answer_sheets = answer_sheet_type.order('created_at')

    # drop down of sheets to capture data for
    @question_sheets = Fe::QuestionSheet.order('label').collect {|s| [s.label, s.id]}
  end

  def create
    @question_sheet = Fe::QuestionSheet.find(params[:question_sheet_id])
    @answer_sheet = @question_sheet.answer_sheets.create

    redirect_to edit_fe_answer_sheet_path(@answer_sheet)
  end

  # display answer sheet for data capture (page 1)
  def edit
    @presenter = Fe::AnswerPagesPresenter.new(self, @answer_sheet, params[:a])
    unless @presenter.active_answer_sheet.pages.present?
      flash[:error] = "Sorry, there are no questions for this form yet."
      if request.env["HTTP_REFERER"]
        redirect_back
      else
        render :text => "", :layout => true
      end
    else
      if get_filter.present?
        # filter presenter entire page list
        all_question_set = @presenter.questions_for_all_pages
        all_question_set.set_filter(get_filter)
        @presenter.filter_pages_from_elements(all_question_set.elements)

        # get first page elements
        question_set = @presenter.questions_for_page(:first)
        question_set.set_filter(get_filter)
        @elements = question_set.elements
        @page = @presenter.pages.first
      else
        # save some processing by not doing any filtering code
        @elements = @presenter.questions_for_page(:first).elements
        @page = @presenter.pages.first
      end
    end
  end

  # display captured answers (read-only)
  def show
    @question_sheet = @answer_sheet.question_sheet
    pf = Fe.table_name_prefix
    @elements = @question_sheet.pages.collect {|p| p.elements.includes(:pages).order("#{pf}pages.number,#{pf}page_elements.position").all}.flatten
    questions = Fe::QuestionSet.new(@elements, @answer_sheet)
    questions.set_filter(get_filter)
    @elements = questions.elements.group_by{ |e| e.pages.first }
  end

  def send_reference_invite(reference = nil)
    @reference = reference || @answer_sheet.reference_sheets.find(params[:reference_id])
    if params[:reference]
      reference_params = params.fetch(:reference)[@reference.id.to_s].permit(:relationship, :title, :first_name, :last_name, :phone, :email, :is_staff)

      @reference.update_attributes(reference_params)
    end
    if @reference.valid?
      @reference.send_invite(request.host)
    end
  end

  def submit
    return false unless validate_sheet
    flash[:notice] = "Your form has been submitted. Thanks!"
    redirect_to root_path
  end

  protected

  # extending classes can override this to set a questions filter
  # see Fe::QuesitonSet#set_filter for more details
  def get_filter
  end

  def answer_sheet_type
    return Fe::ReferenceSheet if params[:controller] == "fe/reference_sheets"
    (params[:answer_sheet_type] || Fe.answer_sheet_class || 'AnswerSheet').constantize
  end

  def get_answer_sheet
    @answer_sheet = answer_sheet_type.find(params[:id])
  end

  def validate_sheet
    unless @answer_sheet.completely_filled_out?
      @presenter = Fe::AnswerPagesPresenter.new(self, @answer_sheet, params[:a])
      render 'incomplete'
      return false
    end
    return true
  end
end
