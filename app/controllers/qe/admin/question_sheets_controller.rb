module Qe
  module Admin
    class QuestionSheetsController < ::ApplicationController

      module M
        extend ActiveSupport::Concern
        included do
          before_filter :get_question_sheet, :only => [:show, :archive, :unarchive, :destroy, :edit, :update, :duplicate]
        end

        # list of all questionnaires/forms to edit
        # GET /question_sheets  
        def index
          @active_question_sheets = Qe::QuestionSheet.active.order('label')
          @archived_question_sheets = Qe::QuestionSheet.archived.order('label')

          respond_to do |format|
            format.html # index.rhtml
            format.xml  { render :xml => @question_sheets.to_xml }
          end
        end

        def archive
          @question_sheet.update_attribute(:archived, true)
          redirect_to :back
        end

        def unarchive
          @question_sheet.update_attribute(:archived, false)
          redirect_to :back
        end

        def duplicate
          @question_sheet.duplicate
          redirect_to :back
        end

        # entry point: display form designer with page 1 and panels loaded
        # GET /question_sheets/1
        def show
          @all_pages = @question_sheet.pages.find(:all)
          @page = @all_pages[0]

          respond_to do |format|
            format.html # show.rhtml
            format.xml  { render :xml => @question_sheet.to_xml }
          end
        end

        # create sheet with inital page, redirect to show
        # POST /question_sheets
        def create
          @question_sheet = Qe::QuestionSheet.new_with_page
          
          respond_to do |format|
            if @question_sheet.save
              format.html { redirect_to admin_question_sheet_path(@question_sheet) }
              format.xml  { head :created, :location => admin_question_sheet_path(@question_sheet) }
            else
              format.html { render :action => "new" }
              format.xml  { render :xml => @question_sheet.errors.to_xml }
            end
          end
        end

        # display sheet properties panel
        # GET /question_sheets/1/edit
        def edit
          respond_to do |format|
            format.js
          end
        end

        # save changes to properties panel (label, language)
        # PUT /question_sheets/1
        def update
          respond_to do |format|
            if @question_sheet.update_attributes(params[:question_sheet], :without_protection => true)
              format.html { redirect_to admin_question_sheet_path(@question_sheet) }
              format.js 
              format.xml  { head :ok }
            else
              format.html { render :action => "edit" }
              format.js   { render :action => "error.js.erb"}
              format.xml  { render :xml => @question_sheet.errors.to_xml }
            end
          end
        end

        # mark sheet as destroyed
        # DELETE /question_sheets/1
        def destroy
          @question_sheet.destroy
          
          respond_to do |format|
            format.html { redirect_to admin_question_sheets_path }
            format.xml  { head :ok }
          end
        end

        protected

        def get_question_sheet
          @question_sheet = Qe::QuestionSheet.find(params[:id])
        end
      end

      include Qe::Admin::BaseControllerConfigs
      include M
    end
  end
end