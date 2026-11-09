module Fe::AccessControlConcern
  extend ActiveSupport::Concern

  private

  # Must not rely on get_answer_sheet having run first: re-declaring a callback
  # moves it to the end of the chain. A request that still has no sheet after
  # loading is left to the action.
  def fe_authorize_answer_sheet!
    return if performed?
    get_answer_sheet if @answer_sheet.nil? && respond_to?(:get_answer_sheet, true)
    return if performed? || @answer_sheet.nil?

    access = action_name == 'show' ? :look : :change
    allowed = respond_to?(:fe_can_use_answer_sheet?, true) && fe_can_use_answer_sheet?(@answer_sheet, access)
    fe_deny!(:answer_sheet) unless allowed
  end

  def fe_require_admin!
    return if performed?

    allowed = respond_to?(:fe_admin?, true) && fe_admin?
    fe_deny!(:admin) unless allowed
  end

  # A subclass, reopened class or prepended module that defines the action
  # replaces fe's and owns its access control, so it must not be gated here.
  def fe_require_admin_for_own_action!
    return unless self.class.instance_method(action_name).owner == Fe::AnswerSheetsControllerConcern

    fe_require_admin!
  end

  # Whatever the host's fe_access_denied does, the request must not continue.
  def fe_deny!(kind)
    fe_access_denied(kind) if respond_to?(:fe_access_denied, true)
    head :forbidden unless performed?
  end
end
