class Fe::ApplicationsController < ApplicationController
  append_before_filter :check_valid_user, :only => [:show, :collated_refs, :no_conf, :no_ref]
  append_before_filter :setup
  append_before_filter :set_title
  
  layout 'fe/application'

  # dashboard
  def index
    redirect_to :action => :show_default
  end
  
  def show_default
    @apply = get_apply
    setup_view
    
    render :template => 'fe/answer_sheets/edit'#, :layout => 'public'
  end
  
  # create app
  def create
    @question_sheet = Fe::QuestionSheet.find(params[:question_sheet_id])
    @apply = @person.applies.build
    
    @apply.save!
    @apply.question_sheets << @question_sheet
    redirect_to apply_path(@apply)
  end
  
  # edit an apply
  def edit
    @apply = Apply.find(params[:id]) unless @apply

    if @apply.applicant == current_user.person
      setup_view
      
      render :template => 'answer_sheets/edit'
    else 
      no_access
    end
    
  end
  
  def show
    @apply = Apply.find(params[:id]) unless @apply
    @answer_sheets = @apply.answer_sheets
    @show_conf = true

    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@apply.sleeve.title}'."
      return
    end
    render :layout => 'admin_apply'
  end
  
  def no_ref
    @apply = Apply.find(params[:id]) unless @apply
    @answer_sheets = [@apply]
    @show_conf = true
    
    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@apply.sleeve.title}'."
      return
    end
    
    render :layout => 'admin_apply', :template => 'applys/show'
  end
  
  def no_conf
    @apply = Apply.find(params[:id]) unless @apply
    @answer_sheets = [@apply]
    @show_conf = false
    
    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@apply.sleeve.title}'."
      return
    end
    
    render :layout => 'admin_apply', :template => 'applys/show'
  end
  
  def collated_refs
    @apply = Apply.find(params[:id]) unless @apply
    @answer_sheets = @apply.references

    if @answer_sheets.empty?
      render :action => :too_old
      #raise "No applicant sheets in sleeve '#{@apply.sleeve.title}'."
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
    eval("ref = @" + type + "_reference = @apply." + type + "_reference")
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
    HrSiapply::YEAR  
  end
  
  def get_person
    @person ||= current_person
    return nil unless @person
    @person.current_address = ::Fe::Address.new(:address_type =>'current') unless @person.current_address
    @person.emergency_address1 = ::Fe::Address.new(:address_type =>'emergency1') unless @person.emergency_address1
    @person.permanent_address = ::Fe::Address.new(:address_type =>'permanent') unless @person.permanent_address
    return @person
  end
  
  def get_apply
    unless @apply
      @person ||= get_person
      # if this is the user's first visit, we will need to create an apply
      if @person.fe_apply.nil?
        create_apply
        @apply.save!
        @person.fe_apply = @app
      else
        @apply ||= @person.fe_apply
      end
    end
    @apply
  end

  def create_apply
    @apply = Fe::Apply.create :applicant_id => @person.id
  end

  def setup_view
    @answer_sheet = @apply
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

