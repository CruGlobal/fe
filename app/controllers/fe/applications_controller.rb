module Fe
  class ApplicationsController < ApplicationController
    include ApplicationControllerConcern

    append_before_filter :check_valid_user, :only => [:show, :collated_refs, :no_conf, :no_ref]
    append_before_filter :setup
    append_before_filter :set_title

    layout 'fe/application'

    # dashboard
    def index
      redirect_to :action => :show_default
    end

    def show_default
      @application = get_application
      setup_view

      render :template => 'fe/answer_sheets/edit'
    end

    # create app
    def create
      @question_sheet = Fe::QuestionSheet.find(params[:question_sheet_id])
      @application = @person.applications.build

      @application.save!
      @application.question_sheets << @question_sheet
      redirect_to fe_application_path(@application)
    end

    # edit an apply
    def edit
      @application = Application.find(params[:id]) unless @application

      if @application.applicant == current_user.person
        setup_view

        render :template => 'fe/answer_sheets/edit'
      else 
        no_access
      end

    end

    def show
      @application = Application.find(params[:id]) unless @application
      @answer_sheets = @application.answer_sheets
      @show_conf = true
      @viewing = true
    end

    def no_ref
      @application = Application.find(params[:id]) unless @application
      @answer_sheets = [@application]
      @show_conf = true
      render :template => 'fe/applications/show'
    end

    def no_conf
      @application = Application.find(params[:id]) unless @application
      @answer_sheets = [@application]
      @show_conf = false
      render :template => 'fe/applications/show'
    end

    def no_access
      redirect_to '/'
    end

    protected

    def setup
      @person = get_person    # current visitor_id
    end

    def get_year
      Application::YEAR  
    end

    def get_person
      @person ||= current_person
      return nil unless @person
      @person.current_address = ::Fe::Address.new(:address_type =>'current') unless @person.current_address
      @person.emergency_address1 = ::Fe::Address.new(:address_type =>'emergency1') unless @person.emergency_address1
      @person.permanent_address = ::Fe::Address.new(:address_type =>'permanent') unless @person.permanent_address
      return @person
    end

    def get_application
      unless @application
        @person ||= get_person
        # if this is the user's first visit, we will need to create an apply
        if @person.application.nil?
          create_application
          @application.save!
          @person.application = @application
        else
          @application ||= @person.application
        end
      end
      @application
    end

    def create_application
      @application = Fe::Application.create :applicant_id => @person.id
    end

    def setup_view
      @answer_sheet = @application
      # edit the first page
      @presenter = Fe::AnswerPagesPresenter.new(self, @answer_sheet)
      @elements = @presenter.questions_for_page(:first).elements
      @page = @presenter.pages.first
      @presenter.active_page ||= @page
    end

    def set_title
      @title = "Form Engine"
    end
  end
end
