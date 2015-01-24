# use a decorator here instead of using my own controller in app/controllers/applications_controller.rb that
# extends Fe::ApplicationsController so that we can use the /fe routes that the engine sets up.  Then we avoid
# having to copy and paste new routes in the engine into this dummy app.
#
Fe::ApplicationsController.class_eval do

  def get_year_tester # get around protected only for testing purposes
    get_year
  end

  protected

  def current_user
    return ::User.find session[:user_id]
  end

  def current_person
    current_user.person
  end
end
