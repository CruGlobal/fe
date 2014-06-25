module Fe::ApplicationControllerConcern
  extend ActiveSupport::Concern

  begin
    included do
      helper_method :fe_user
    end
  rescue ActiveSupport::Concern::MultipleIncludedBlocks
  end

  def fe_user
    return nil unless current_user
    @fe_user ||= Fe::User.find_by_user_id(current_user.id)
    if @fe_user && !session[:login_stamped]
      @fe_user.update_attribute(:last_login, Time.now)
      session[:login_stamped] = true
    end
    @fe_user
  end

  def check_valid_user
    unless fe_user
      # TODO redirect to somewhere better
      redirect_to :controller => :admin, :action => :no_access
      return false
    end
  end
end
