# gather reference information from Applicant
module Fe
  class ReferencePagesController < ApplicationController
    skip_before_action :cas_filter, raise: false
    skip_before_action :authentication_filter, raise: false

    layout nil

    before_action :setup

    MONTHS_KNOWN_OPTIONS = [
      ["3 months", 3],
      ["6 months", 6],
      ["1 year", 12],
      ["2 years", 24],
      ["3 or more years", 36]
    ]

    # Allow applicant to edit reference
    # /applications/1/reference_page/edit
    # js: provide a partial to replace the answer_sheets page area
    # html?: return a full page for editing reference independantly (after submission)
    def edit
      @references = @application.reference_sheets

      # NEXT: skipping all the fancy answer sheets stuff since all custom pages come after those
      @next_page = next_custom_page(@application, 'reference_page')
    end

    def update
      #update_references
      head :ok
    end

    private
    def setup
      @application = Application.find(params[:application_id])
    end

  end
end
