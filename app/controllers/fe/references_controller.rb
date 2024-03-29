# for Reference completing answer sheet
# TODO determine how this relates to Fe::ReferenceSheetsController and if we can delete one of the two
module Fe
  class ReferencesController < ApplicationController
    skip_before_action :cas_filter, raise: false
    skip_before_action :authentication_filter, raise: false

    before_action :setup

    layout 'public'

    # AnswerSheet for reference to fill in
    # /applications/1/references/{token}
    def edit
      ref = Fe::ReferenceSheet.find_by_access_key(params[:id])
      redirect_to edit_fe_reference_sheet_path(ref, a: params[:id])
    end

    # final submission
    def submit
      @reference = @application.references.find(params[:id])
      @reference.submit!

      # Send Reference Thank You
      Fe::Notifier.notification(@reference.email,
                                    Fe.from_email,
                                    "Reference Thank You",
                                    {'reference_full_name' => @reference.name,
                                     'applicant_full_name' => @application.applicant.informal_full_name}).deliver


      # Send Reference Completion Notice
      Fe::Notifier.notification(@application.applicant.email,
                                    Fe.from_email,
                                    "Reference Complete",
                                    {'reference_full_name' => @reference.name,
                                     'applicant_full_name' => @application.applicant.informal_full_name,
                                     'reference_submission_date' => @reference.submitted_at.strftime("%m/%d/%Y")}).deliver

    end


    def show
      @reference = @application.references.find_by_access_key(params[:id])

      if @reference.nil?
        render action: :edit
      else
        @answer_sheet = @reference
        @question_sheet = @answer_sheet.question_sheet
        @elements = []
        if @question_sheet
          @question_sheet.pages.order(:number).each do |page|
            @elements << page.elements.where("#{Element.table_name}.kind not in (?)", %w(Fe::Section Fe::Paragraph)).all
          end
          @elements = @elements.flatten
          @elements = QuestionSet.new(@elements, @answer_sheet).elements.group_by(&:page_id)
        end
      end
    end

    def send_invite
      # Save references on page first
      #update_references

      @reference = Fe::ReferenceSheet.find(params[:id])
      send_reference_invite(@reference)
    end

    private
    def setup
      @application = Application.find(params[:application_id])
    end
  end
end
