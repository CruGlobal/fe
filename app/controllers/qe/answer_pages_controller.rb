module Qe
  class AnswerPagesController < ::ApplicationController
  	
		module M
			extend ActiveSupport::Concern
			included do
				before_filter :get_answer_sheet, :only => [:edit, :update, :save_file, :index]
			end


			def edit
		    @elements = @presenter.questions_for_page(params[:id]).elements
		    @page = Qe::Page.find(params[:id]) || Qe::Page.find_by_number(1)
		    
		    render :partial => 'answer_page', :locals => { :show_first => nil }
		  end

		  # validate and save captured data for a given page
		  # PUT /answer_sheets/1/pages/1
		  def update
		    @page = Qe::Page.find(params[:id])
		    questions = @presenter.all_questions_for_page(params[:id])
		    questions.post(params[:answers], @answer_sheet)
		    
		    questions.save
		    
		    @elements = questions.elements
		    
		    # Save references
		    if params[:reference].present?
		      params[:reference].each do |id, values|
		        ref = @answer_sheet.reference_sheets.find(id)
		        # if the email address has changed, we have to trash the old reference answers
		        ref.attributes = values
		        ref.save(:validate => false)
		      end
		    end
		    @presenter.active_page = nil
		    @answer_sheet.touch
		    respond_to do |format|
		      format.js
		      #format.html
		    end
		  end
		  
		  def save_file
		    if params[:Filedata]
		      @page = Qe::Page.find(params[:id])
		      @presenter.active_page = @page
		      question = Qe::Element.find(params[:question_id])
		      answer = Qe::Answer.find(:first, :conditions => {:answer_sheet_id => @answer_sheet.id, :question_id => question.id})
		      question.answers = [answer] if answer

		      answer = question.save_file(@answer_sheet, params[:Filedata])
		      
		      render :update do |page|
		        page << <<-JS
		          $('#attachment_field_#{question.id}_filename').html('Current File: #{link_to(answer.attachment_file_name, answer.attachment.url)}')
		          $('#attachment_field_#{question.id}_filename').effect('highlight')
		        JS
		      end
		    else
		      respond_to do |format|
		        format.js { head :ok }
		      end
		    end
		  end
		  
		  protected
		  
		  def get_answer_sheet
		    @answer_sheet = answer_sheet_type.find(params[:answer_sheet_id])
		    @presenter = Qe::AnswerPagesPresenter.new(self, @answer_sheet, params[:a])
		  end

		  def answer_sheet_type
		    (params[:answer_sheet_type] || Qe.answer_sheet_class || 'Qe::AnswerSheet').constantize
		  end
		end
		
		include Qe::BaseControllerConfigs
		include M
	end
end