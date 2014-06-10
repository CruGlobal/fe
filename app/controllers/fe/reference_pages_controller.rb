# gather reference information from Applicant
class ReferencePagesController < ApplicationController
  skip_before_filter :cas_filter
  skip_before_filter :authentication_filter
  
  layout nil
  
  before_filter :setup

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
    @application = Apply.find(params[:application_id])
  end  
  
end
