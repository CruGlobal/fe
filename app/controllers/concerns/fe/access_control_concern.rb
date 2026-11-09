module Fe::AccessControlConcern
  extend ActiveSupport::Concern

  private

  # Asks the host app whether the current person may use the loaded answer
  # sheet. Runs only after the sheet is loaded; a request with no sheet is left
  # to the action's own handling.
  def fe_authorize_answer_sheet!
    return if performed? || @answer_sheet.nil?

    access = action_name == 'show' ? :look : :change
    allowed = respond_to?(:fe_can_use_answer_sheet?, true) && fe_can_use_answer_sheet?(@answer_sheet, access)
    fe_deny!(:answer_sheet) unless allowed
  end

  # The host's fe_access_denied may render or redirect; whatever it does, the
  # request must not continue, so an unanswered request gets a 403.
  def fe_deny!(kind)
    fe_access_denied(kind) if respond_to?(:fe_access_denied, true)
    head :forbidden unless performed?
  end
end
