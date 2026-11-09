class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  def check_valid_user
  end

  def fe_can_use_answer_sheet?(answer_sheet, access)
    true
  end

  def fe_admin?
    true
  end
end
