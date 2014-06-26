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
    @fe_user ||= Fe::User.where(:user_id => current_user.id).first_or_create
    if @fe_user
      @fe_user.update_attribute(:last_login, Time.now)
      session[:login_stamped] = true
    end
    @fe_user
  end

  def current_person
    #raise "no user" unless current_user
    return nil unless current_user
    current_user.fe_person || Fe::Person.create(:user_id => current_user.id)
  end

  def check_valid_user
    unless fe_user
      # TODO redirect to somewhere better
      redirect_to "/", flash: { error: "Access denied" }
      return false
    end
  end
end
