# gather payment information from Applicant
module Fe
  class PaymentsController < ApplicationController
    prepend_before_filter :ssm_login_required, :except => [:edit, :update]
    prepend_before_filter :cas_filter, :authentication_filter, :only => [:edit, :update]
    before_filter :setup, :except => [:edit, :update, :approve]

    # Allow applicant to edit payment
    # /applications/1/payment_page/edit
    # js: provide a partial to replace the answer_sheets page area
    def edit
      @payment = Fe::Payment.find(params[:id])
      @application = @payment.answer_sheet
      # if this isn't a staff payment they shouldn't be here for this staff person
      unless 'Staff' == @payment.payment_type && current_person.isStaff?
        render('no_access') and return
      end
      @payment.status = "Approved" # set the status so a default radio button will be selected
    end

    def create
      Fe::Payment.transaction do
        @payment = @application.payments.new(payment_params)
        if @application.payments.non_denied.length > 0
          @payment.errors.add(:base, "You have already submitted a payment for this application.")
          render :action => "error"
        else
          @payment.amount = Application::COST
          @payment.status = 'Pending'
          if @payment.valid?
            case @payment.payment_type
            when "Credit Card"
              card_type = params[:payment][:card_type]

              creditcard = ActiveMerchant::Billing::CreditCard.new(
                :brand       => card_type,
                :number     => @payment.card_number,
                :month      => @payment.expiration_month,
                :year       => @payment.expiration_year,
                :verification_value => @payment.security_code,
                :first_name => @payment.first_name,
                :last_name  => @payment.last_name
              )

              if creditcard.valid?
                response = GATEWAY.purchase(@payment.amount * 100, creditcard)

                if response.success?
                  @payment.approve!
                  # TODO: Send notification email
                else
                  @payment.errors.add(:base, "Credit card transaction failed: #{response.message}")
                  #Send email this way instead of raising error in order to still give an error message to user.
                  # Fe::Notifier.notification('programmers@cojourners.com', # RECIPIENTS
                  #                     "sp_error@uscm.org", # FROM
                  #                     "Credit Card Error", # LIQUID TEMPLATE NAME
                  #                     {'error' => "Credit card transaction failed: #{response.message} \n #{response.inspect} \n #{creditcard.inspect}"}).deliver
                end
              else
                @payment.errors.add(:card_number, "is invalid.  Check the number and/or the expiration date.")
              end
            when "Mail"
              @payment.approve!
            when "Staff"
              @payment.save
              send_staff_payment_request(@payment)
            end
          end
        end
      end
    end

    def update
      @payment = Fe::Payment.includes({:answer_sheet => :applicant}).find(params[:id])
      @application = @payment.answer_sheet
      @person = @application.applicant
      @payment.status = params[:payment][:status]
      staff_approval
      @payment.save!
      staff_payment_processed_email(@payment)
      @payment.answer_sheet.complete
    end

    def approve
      @payment = Fe::Payment.find(params[:id])
      @application = @payment.answer_sheet
      @payment.auth_code = si_user.user.person.accountNo
      case @payment.payment_type
      when 'Staff'
        staff_approval
        staff_payment_processed_email(@payment)
      when 'Mail'
        Fe::Notifier.notification(@application.email, # RECIPIENTS
                                  Fe.from_email, # FROM
                                  "Check Received", # LIQUID TEMPLATE NAME
                                  {'name' => @application.applicant.informal_full_name}).deliver
      end
      @payment.approve!
      @payment.application.complete
    end

    def staff_search
      #binding.pry
      #@payment = @application.payments.new(params[:payment].slice(:payment_type, :payment_account_no, :auth_code))
      @payment = @application.payments.new(staff_search_payment_params)
      if @payment.staff_first.to_s.strip.empty? || @payment.staff_last.to_s.strip.empty?
        render; return
      end
      #@results = Staff.find(:all, :order => 'lastName, firstName', :conditions => ["(firstName like ? OR preferredName like ?) AND lastName like ? and removedFromPeopleSoft <> 'Y'", @payment.staff_first+'%', @payment.staff_first+'%', @payment.staff_last+'%'])
      @results = Staff.order('lastName, firstName').where("(firstName like ? OR preferredName like ?) AND lastName like ? and removedFromPeopleSoft <> 'Y'", @payment.staff_first+'%', @payment.staff_first+'%', @payment.staff_last+'%')
    end

    def destroy
      @payment = @application.payments.find(params[:id])
      @payment.destroy
    end

    protected

    def setup
      if app_user && app_user.can_su_application?
        @application = Application.find(params[:application_id])
      else
        @application = current_person.applications.find(params[:application_id])
      end
    end

    def send_staff_payment_request(payment)
      @person = @application.applicant
      staff = Staff.find_by_accountNo(payment.payment_account_no)
      raise "Invalid staff payment request: " + payment.inspect if staff.nil?
      Fe::Notifier.notification(staff.email, # RECIPIENTS
                                Fe.from_email, # FROM
                                "Staff Payment Request", # LIQUID TEMPLATE NAME
                                {'staff_full_name' => staff.informal_full_name, # HASH OF VALUES FOR REPLACEMENT IN LIQUID TEMPLATE
                                  'applicant_full_name' => @person.informal_full_name,
                                  'applicant_email' => @person.email,
                                  'applicant_home_phone' => @person.current_address.home_phone,
                                  'payment_request_url' => url_for(:action => :edit, :application_id => @application.id, :id => @payment.id)},
                                  {:format => :html}).deliver
    end

    def staff_approval
      @payment.auth_code = current_person.accountNo
      if @payment.status == "Other Account"
        @payment.payment_account_no = params[:other_account]
        @payment.approve!
      end
    end

    def staff_payment_processed_email(payment)
      # Send appropriate email
      if payment.approved?
        # Send receipt to applicant
        Fe::Notifier.notification(@application.applicant.email, # RECIPIENTS
                                  Fe.from_email, # FROM
                                  "Applicant Staff Payment Receipt", # LIQUID TEMPLATE NAME
                                  {'applicant_full_name' => @application.applicant.informal_full_name}).deliver
        # Send notice to Tool Owner
        Fe::Notifier.notification(Fe.from_email, # RECIPIENTS - HARD CODED!
                                  "help@campuscrusadeforchrist.com", # FROM
                                  "Tool Owner Payment Confirmation", # LIQUID TEMPLATE NAME
                                  {'payment_amount' => "$" + @payment.amount.to_s,
                                    'payment_account_no' => @payment.payment_account_no,
                                    'payment_auth_code' => @payment.auth_code,
                                    'payment_id' => @payment.id}).deliver
      else
        # Sent notice to applicant that payment was declined
        Fe::Notifier.notification(@application.email, # RECIPIENTS
                                  Fe.from_email, # FROM
                                  "Payment Refusal", # LIQUID TEMPLATE NAME
                                  {'applicant_full_name' => @application.applicant.informal_full_name}).deliver
      end
    end

    def payment_params
      params.require(:payment).permit(:payment_type, :payment_account_no, :auth_code, :first_name, :last_name, :address,
                                     :city, :state, :zip, :card_number, :card_type, :expiration_month, :expiration_year, :security_code)
    end

    def staff_search_payment_params
      params.require(:payment).permit(:payment_type, :staff_first, :staff_last)
    end
  end
end
