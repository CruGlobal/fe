class Fe::Admin::ElementsController < ApplicationController
  before_filter :check_valid_user
  layout 'fe/fe.admin'

  before_filter :get_page

  # GET /element/1/edit
  def edit
    @element = @page.all_elements.find(params[:id])

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
    @questions = params[:element_type].constantize.active.shared.order('label')

    @style = element_params[:style]
    if @style
      @questions = @questions.where(:style => @style).to_a.uniq
    end
  end

  def use_existing
    @element = Fe::Element.find(params[:id]) # NOTE the enclosing app might want to override this method and check that they have access to the questionnaire that the existing element is used on
    # Don't put the same question on a questionnaire twice
    unless @page.question_sheet.elements.include?(@element)
      @page_element = Fe::PageElement.create(:element => @element, :page => @page)
    end
    @question_sheet = @page.question_sheet
    render :create
  end

  def copy_existing
    @element = Fe::Element.find(params[:id]) # NOTE the enclosing app might want to override this method and check that they have access to the questionnaire that the existing element is used on
    # duplicate the elements
    @element = @element.duplicate(@page)
    @element.update_attribute(:share, false)
    @page_element = Fe::PageElement.where(element: @element, page: @page).first_or_create
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
    @element = @page.all_elements.find(params[:id])

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
    @element = @page.all_elements.find(params[:id])
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
          @page.all_elements.find(grid_id).elements.each do |element|
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
    element = @page.all_elements.find(params[:draggable_element].split('_')[1])  # element being dropped
    target = @page.all_elements.find(params[:id])

    if [params[:before], params[:after]].include?('true')
      # move the element out of its parent and back onto the page directly, placing it before the target
      page_element = Fe::PageElement.where(page_id: @page.id, element_id: element.id).first_or_create
      @page.page_elements << page_element

      parent_element = element.question_grid || element.choice_field
      parent_page_element = @page.page_elements.find_by(element_id: parent_element.id)
      if params[:before]
        page_element.insert_at(parent_page_element.position)
      else
        page_element.insert_at(parent_page_element.position + 1)
      end

      # remove question grid / choice_field ref since it's directly on the page now
      element.update_attributes(question_grid_id: nil, choice_field_id: nil)
      return
    end

    case target.class.to_s
    when 'Fe::QuestionGrid', 'Fe::QuestionGridWithTotal'
      # abort if the element is already in this box
      if element.question_grid_id == params[:id].to_i
        render :nothing => true
      else
        element.question_grid_id = params[:id]
        element.save!
      end
    when 'Fe::ChoiceField'
      # abort if the element is already in this box
      if element.choice_field_id == params[:id].to_i
        render :nothing => true
      else
        element.choice_field_id = params[:id]
        element.save!
      end
    end
    # Remove page element for this page since it's now in a grid
    Fe::PageElement.where(:page_id => @page.id, :element_id => element.id).first.try(:destroy)
  end

  def remove_from_grid
    element = @page.all_elements.find(params[:id])
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
    element = @page.all_elements.find(params[:id])
    @element = element.duplicate(@page, element.question_grid || element.question_grid_with_total || element.choice_field)
    respond_to do |format|
      format.js
    end
  end

  private
  def get_page
    @page = Fe::Page.find(params[:page_id])
  end

  def element_params
    params.fetch(:element, {}).permit({label_translations: Fe::LANGUAGES.keys},
                                      {tip_translations: Fe::LANGUAGES.keys},
                                      {content_translations: Fe::LANGUAGES.keys},
                                      {rating_before_label_translations: Fe::LANGUAGES.keys},
                                      {rating_after_label_translations: Fe::LANGUAGES.keys},
                                      {rating_na_label_translations: Fe::LANGUAGES.keys},
                                      :rating_before_label, :rating_after_label, :rating_na_label,
                                      :style, :label, :tooltip,
                                      :position, :source, :value_xpath,
                                      :text_xpath, :question_grid_id, :cols, :total_cols, :css_id, :css_class,
                                      :related_question_sheet_id, :conditional_id, :hide_option_labels, :slug,
                                      :required, :is_confidential, :hide_label, :object_name, :attribute_name,
                                      :max_length, :content, :conditional_type, :conditional_id, :conditional_answer,
                                      :share)
  end

end
