class Fe::SubmitPagesController < ApplicationController

  before_action :setup
  skip_before_action :get_answer_sheet

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
