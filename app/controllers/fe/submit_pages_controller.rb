class Fe::SubmitPagesController < ApplicationController
  include Fe::AccessControlConcern

  before_action :setup
  before_action :fe_authorize_answer_sheet!
  skip_before_action :get_answer_sheet, raise: false

  layout nil

  def edit
    @next_page = next_custom_page(@application, 'submit_page')
  end

  # save any changes on the submit_page (for auto-save, no server-validation)
  def update
    head :ok
  end

  private

  def setup
    @application = @answer_sheet = Fe.answer_sheet_class.constantize.find(params[:application_id]) unless @application
  end
end
