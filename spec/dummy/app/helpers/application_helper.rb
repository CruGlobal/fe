module ApplicationHelper
  # apps will define their own implementation of this, to facilitate tests running just allow anyone
  def user_signed_in?
    true
  end

  # apps will define their own implementation of this, to facilitate tests running just allow anyone
  def destroy_user_session_path
    "/sessions/destroy"
  end
end
