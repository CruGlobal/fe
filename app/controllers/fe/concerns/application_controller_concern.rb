module Fe::ApplicationControllerConcern
  extend ActiveSupport::Concern

  begin
    included do
      helper_method :fe_user
      before_filter :set_locale
    end
  rescue ActiveSupport::Concern::MultipleIncludedBlocks
  end

  def fe_user
    return nil unless current_user
    @fe_user ||= Fe::User.where(:user_id => current_user.id).first
    if @fe_user
      @fe_user.update_attribute(:last_login, Time.now)
      session[:login_stamped] = true
    end
    @fe_user
  end

  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first if request.env['HTTP_ACCEPT_LANGUAGE'].present?
  end

  def set_locale
    session[:locale] = params[:locale] if params[:locale]
    session[:locale] ||= extract_locale_from_accept_language_header || I18n.default_locale
    if @answer_sheet
      session[:locale] = I18n.default_locale unless @answer_sheet.languages.include?(session[:locale])
    end
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
