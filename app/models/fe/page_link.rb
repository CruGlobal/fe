# represents a link to a page for the page_list sidebar or next page links
module Fe
  class PageLink
    attr_accessor :dom_id, :load_path, :page
    attr_accessor :save_path  # to save current page

    def initialize(load_path, dom_id, page)
      @load_path = load_path
      @dom_id = dom_id
      @page = page
    end

    def label(locale = nil)
      page.label(locale)
    end

  end
end
