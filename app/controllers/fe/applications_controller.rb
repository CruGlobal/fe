class Fe::ApplicationsController < ApplicationController
  append_before_filter :check_valid_user, :only => [:show, :collated_refs, :no_conf, :no_ref]
  append_before_filter :setup
  append_before_filter :set_title
  
  layout 'fe/application'

  puts "IN FE Fe::ApplicationsController"

  # dashboard
  def index
    redirect_to :action => :show_default
  end
  
  def show_default
    @application = get_application
    setup_view
    
    render :template => 'fe/answer_sheets/edit'#, :layout => 'public'
  end
  
  # create app
  def create
    @question_sheet = Fe::QuestionSheet.find(params[:question_sheet_id])
    @application = @person.applies.build
    
    @application.save!
    @application.question_sheets << @question_sheet
    redirect_to application_path(@application)
  end
  
  # edit an application
  def edit
    @application = Apply.find(params[:id]) unless @application

    if @application.applicant == current_user.person
      setup_view
      
      render :template => 'answer_sheets/edit'
    else 
      no_access
    end
    
  end
  
  def show
    @application = Apply.find(params[:id]) unless @application
    @answer_sheets = @application.answer_sheets
    @show_conf = true

    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@application.sleeve.title}'."
      return
    end
    render :layout => 'admin_application'
  end
  
  def no_ref
    @application = Apply.find(params[:id]) unless @application
    @answer_sheets = [@application]
    @show_conf = true
    
    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@application.sleeve.title}'."
      return
    end
    
    render :layout => 'admin_application', :template => 'applications/show'
  end
  
  def no_conf
    @application = Apply.find(params[:id]) unless @application
    @answer_sheets = [@application]
    @show_conf = false
    
    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@application.sleeve.title}'."
      return
    end
    
    render :layout => 'admin_application', :template => 'applications/show'
  end
  
  def collated_refs
    @application = Apply.find(params[:id]) unless @application
    @answer_sheets = @application.references

    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@application.sleeve.title}'."
      return
    end

    @reference_question_sheet = Fe::QuestionSheet.find(2) #TODO: constant

    setup_reference("staff")
    setup_reference("discipler")
    setup_reference("roommate")
    setup_reference("friend")
    
    @show_conf = true
  end

  def setup_reference(type)
    ref = nil
    eval("ref = @" + type + "_reference = @application." + type + "_reference")
    raise type unless ref
    answer_sheet = ref
    question_sheet = answer_sheet.question_sheet
    if question_sheet
      elements = []
      question_sheet.pages.order(:number).each do |page|
        elements << page.elements.where("#{Fe::Element.table_name}.kind not in (?)", %w(Fe::Paragraph)).all
      end
      elements = elements.flatten
      elements.reject! {|e| e.is_confidential} if @show_conf == false
      eval("@" + type + "_elements = Fe::QuestionSet.new(elements, answer_sheet).elements")
    else
      eval("@" + type + "_elements = []")
    end

  end
  
  def no_access
    redirect_to '/'
  end

protected
  def setup
    @person = get_person    # current visitor_id
  end

  def get_year
    HrSiApplication::YEAR  
  end
  
  def get_person
    @person ||= current_person
    @person.current_address = ::Fe::Address.new(:address_type =>'current') unless @person.current_address
    @person.emergency_address1 = ::Fe::Address.new(:address_type =>'emergency1') unless @person.emergency_address1
    @person.permanent_address = ::Fe::Address.new(:address_type =>'permanent') unless @person.permanent_address
    return @person
  end
  
  def get_application
    unless @application
      @person ||= get_person
      # if this is the user's first visit, we will need to create an hr_si_application
      if @person.fe_application.nil?
        @app = Fe::Application.create
        @app.save!
        @person.fe_application = @app
      end
      if @person.fe_application.fe_apply.nil?
        @application = @person.fe_application.find_or_create_apply
        @person.fe_application.save!
      else
        @application ||= @person.fe_application.fe_apply
      end
    end
    @application
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

