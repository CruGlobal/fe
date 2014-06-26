class Fe::Admin::EmailTemplatesController < ApplicationController
  before_filter :check_valid_user
  layout 'fe/fe.admin'
  
  def index 
    @email_templates = Fe::EmailTemplate.order('name')
  
    respond_to do |format|
      format.html
    end
  end
  
  def new 
    @email_template = Fe::EmailTemplate.new
  
    respond_to do |format|
      format.html
    end
  end
  
  def edit
    @email_template = Fe::EmailTemplate.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @email_template = Fe::EmailTemplate.new(params[:email_template])
    
    respond_to do |format|
      if @email_template.save
        format.html { redirect_to admin_email_templates_path }
      else
        format.html { render :action => :new }
      end
    end
  end
  
  def update 
    @email_template = Fe::EmailTemplate.find(params[:id])
    
    respond_to do |format|
      if @email_template.update_attributes(params[:email_template])
        format.html { redirect_to admin_email_templates_path }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def destroy
    @email_template = Fe::EmailTemplate.find(params[:id])
    @email_template.destroy

    respond_to do |format|
      format.html { redirect_to email_templates_path }
    end
  end
end
