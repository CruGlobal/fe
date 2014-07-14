class Fe::SubmitPagesController < ApplicationController
  before_filter :setup

  layout nil
  
  def edit
    @next_page = next_custom_page(@application, 'submit_page')
  end
  
  # save any changes on the submit_page (for auto-save, no server-validation)
  def update
    head :ok
  end
  
  # submit application
  def submit
    valid = true
    
    @application.errors.add(:base, "You must supply at least one payment.") if @application.payments.length < 1
    
    if @application.errors.messages.length == 0
      @application.submit!
      
      # send references 
      @application.references.each do |reference| 
        send_reference_invite(reference) unless reference.email_sent?
      end
    else
      render :action => 'error'
    end
  end

 private
  def setup
    @application = Fe::Application.find(params[:application_id]) unless @application
  end  
end
