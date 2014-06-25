module Fe::ApplicationControllerConcern
  extend ActiveSupport::Concern

  begin
    included do
      helper_method :fe_user
    end
  rescue ActiveSupport::Concern::MultipleIncludedBlocks
  end

  def fe_user
    return nil unless user
    @fe_user ||= SiUser.find_by_ssm_id(user.id)
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
