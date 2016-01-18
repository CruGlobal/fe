module Fe
  module AnswerPagesPresenterConcern
    extend ActiveSupport::Concern

    begin
      included do
        attr_accessor :active_answer_sheet, :page_links, :active_page, :pages
      end
    rescue ActiveSupport::Concern::MultipleIncludedBlocks
    end

    def initialize(controller, answer_sheets, a = nil, custom_pages = nil, show_hidden_pages = false)
      super(controller)
      @answer_sheets = Array.wrap(answer_sheets)
      @active_answer_sheet = @answer_sheets.first
      initialize_pages(@active_answer_sheet, show_hidden_pages)

      @page_links = page_list(@answer_sheets, a, custom_pages)
    end

    def questions_for_page(page_id=:first)
      @active_page = page_id == :first ? pages.first : pages.detect {|p| p.id == page_id.to_i}
      begin
        base = @active_answer_sheet.pages.visible.includes(:elements)
        @active_page ||= page_id == :first ? base.first : base.find(page_id)
      rescue ActiveRecord::RecordNotFound
        @active_page = nil
      end
      Fe::QuestionSet.new(@active_page ? @active_page.elements : [], @active_answer_sheet)
    end

    def all_questions_for_page(page_id=:first)
      @active_page = page_id == :first ? pages.first : pages.detect {|p| p.id == page_id.to_i}
      base = @active_answer_sheet.pages.visible
      @active_page ||= page_id == :first ? base.first : base.find(page_id)
      Fe::QuestionSet.new(@active_page ? @active_page.all_elements : [], @active_answer_sheet)
    end

    def questions_for_all_pages
      Fe::QuestionSet.new(@active_answer_sheet.question_sheet.all_elements, @active_answer_sheet)
    end

    # title
    def sheet_title
      @active_answer_sheet.question_sheet.label
    end

    def active_page_link
      return unless @active_page
      link = new_page_link(@active_answer_sheet, @active_page)
      link.save_path = fe_answer_sheet_page_path(@active_answer_sheet, @active_page)
      link
    end

    def prev_page
      active_page_dom_id = active_page_link.dom_id

      this_page = @page_links.find {|p| p.dom_id == active_page_dom_id}
      index = @page_links.index(this_page)
      return nil if index == 0
      @page_links.at( index - 1 ) unless this_page.nil?
    end

    def next_page
      active_page_dom_id = active_page_link.dom_id

      this_page = @page_links.find {|p| p.dom_id == active_page_dom_id}
      @page_links.at( @page_links.index(this_page) + 1 ) unless this_page.nil?
    end

    def reference?
      if @active_answer_sheet.respond_to?(:apply_sheet)
        @active_answer_sheet.apply_sheet.sleeve_sheet.assign_to == 'reference'
      else
        false
      end
    end

    def initialize_pages(answer_sheet, show_hidden_pages = false)
      @pages = []
      answer_sheet.question_sheets.each do |qs|
        pages = show_hidden_pages ? qs.pages : qs.pages.visible
        pages.each do |page|
          @pages << page
        end
      end
    end

    def started?
      active_answer_sheet.question_sheets.each do |qs|
        qs.pages.visible.each do |page|
          return true if page.started?(active_answer_sheet)
        end
      end
    end

    def new_page_link(answer_sheet, page, a = nil)
      Fe::PageLink.new(edit_fe_answer_sheet_page_path(answer_sheet, page, :a => a), dom_page(answer_sheet, page), page) if page
    end

    # filters the pages and pages_list such that only pages for which there
    # are elements in the elements array passed in are kept
    def filter_pages_from_elements(elements)
      pages_from_elements = elements.collect{ |e| e.pages }.flatten.uniq
      pages.reject! { |p| !pages_from_elements.include?(p) }
      @page_links.reject! { |pl| !pages_from_elements.include?(pl.page) }
      true
    end

    protected

    # for pages_list sidebar
    def page_list(answer_sheets, a = nil, custom_pages = nil)
      page_list = []
      answer_sheets.each do |answer_sheet|
        pages.each do |page|
          page_list << new_page_link(answer_sheet, page, a)
        end
      end
      page_list = page_list + custom_pages unless custom_pages.nil?
      page_list
    end

    # page is identified by answer sheet, so can have multiple sheets loaded at once
    def dom_page(answer_sheet, page)
      dom = "#{dom_id(answer_sheet)}-#{dom_id(page)}"
      dom += "-no_cache" if page.no_cache
      dom
    end
  end
end
