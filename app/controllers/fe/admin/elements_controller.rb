class Fe::Admin::ElementsController < ApplicationController
  before_filter :check_valid_user
  layout 'fe/fe.admin'
  
  before_filter :get_page
  
  # GET /element/1/edit
  def edit
    @element = Fe::Element.find(params[:id])
    
    # for dependencies
    if @element.question?
      (3 - @element.conditions.length).times { @element.conditions.build }
      @questions_before_this = @page.questions_before_position(@element.position(@page)) 
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def new
    @questions = params[:element_type].constantize.active.order('label')
    puts "\nFe::Admin::ElementsController#new @question.to_sql: #{@questions.to_sql}"
    @questions = @questions.to_a # try to fix double distinct sql error by getting the elements here, since to_sql at this point is correct

    @style = element_params[:style]
    if @style
      @questions = @questions.where(:style => @style).uniq
    end
  end
  
  def use_existing
    @element = Fe::Element.find(params[:id])
    # Don't put the same question on a questionnaire twice
    unless @page.question_sheet.elements.include?(@element)
      @page_element = Fe::PageElement.create(:element => @element, :page => @page)
    end
    @question_sheet = @page.question_sheet
    render :create
  end

  # POST /elements
  def create
    @element = params[:element_type].constantize.new(element_params)
    @element.required = true if @element.question?
    @question_sheet = @page.question_sheet

    respond_to do |format|
      if @element.save
        @page_element = Fe::PageElement.create(:element => @element, :page => @page)
        format.js
      else
        format.js { render :action => 'error.js.erb' }
      end
    end
  end

  # PUT /elements/1
  def update
    @element = Fe::Element.find(params[:id])

    respond_to do |format|
      if @element.update_attributes(element_params)
        format.js
      else
        format.js { render :action => 'error.js.erb' }
      end
    end
  end

  # DELETE /elements/1
  # DELETE /elements/1.xml
  def destroy
    @element = Fe::Element.find(params[:id])
    # Start by removing the element from the page
    page_element = Fe::PageElement.where(:element_id => @element.id, :page_id => @page.id).first
    page_element.destroy if page_element
    
    # If this element is not on any other pages, is not a question or has no answers, Destroy it
    if @element.reuseable? && (Fe::PageElement.where(:element_id => params[:id]).present? || @element.has_response?)
      @element.update_attributes(:question_grid_id => nil, :conditional_id => nil)
    else
      @element.destroy
    end

    respond_to do |format|
      format.js
    end
  end
  
  def reorder 
    # since we don't know the name of the list, just find the first param that is an array
    params.each_key do |key| 
      if key.include?('questions_list')
        grid_id = key.sub('questions_list_', '').to_i
        # See if we're ordering inside of a grid
        if grid_id > 0
          Fe::Element.find(grid_id).elements.each do |element|
            if index = params[key].index(element.id.to_s)
              element.position = index + 1 
              element.save(:validate => false)
            end
          end
        else
          @page.page_elements.each do |page_element|
            if index = params[key].index(page_element.element_id.to_s)
              page_element.position = index + 1 
              page_element.save(:validate => false)
              @element = page_element.element
            end
          end
        end
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def drop
    element = Fe::Element.find(params[:draggable_element].split('_')[1])  # element being dropped
    target = Fe::Element.find(params[:id])
    case target.class.to_s
    when 'QuestionGrid', 'QuestionGridWithTotal'
      # abort if the element is already in this box
      if element.question_grid_id == params[:id].to_i
        render :nothing => true
      else
        element.question_grid_id = params[:id]
        element.save!
      end
    when 'ChoiceField'
      # abort if the element is already in this box
      if element.conditional_id == params[:id].to_i
        render :nothing => true
      else
        element.conditional_id = params[:id]
        element.save!
      end
    end
    # Remove page element for this page since it's now in a grid
    Fe::PageElement.where(:page_id => @page.id, :element_id => element.id).first.try(:destroy)
  end
  
  def remove_from_grid
    element = Fe::Element.find(params[:id])
    Fe::PageElement.create(:element_id => element.id, :page_id => @page.id) unless Fe::PageElement.where(:element_id => element.id, :page_id => @page.id).first
    if element.question_grid_id
      element.set_position(element.question_grid.position(@page), @page) 
      element.question_grid_id = nil
    elsif element.choice_field_id
      element.set_position(element.choice_field.position(@page), @page) 
      element.choice_field_id = nil
    end
    element.save!
    render :action => :drop
  end
  
  def duplicate
    element = Fe::Element.find(params[:id])
    @element = element.duplicate(@page, element.question_grid || element.choice_field)
    respond_to do |format|
      format.js 
    end
  end
  
  private
  def get_page
    @page = Fe::Page.find(params[:page_id])
  end

  def element_params
    params.fetch(:element, {}).permit(:style, :label, :tooltip, :position, :source, :value_xpath, :text_xpath, :question_grid_id, :cols, :total_cols, :css_id, :css_class, :related_question_sheet_id, :conditional_id, :hide_option_labels, :slug, :required, :is_confidential, :hide_label, :object_name, :attribute_name, :max_length, :content, :conditional_type, :conditional_id, :conditional_answer)
  end

end
