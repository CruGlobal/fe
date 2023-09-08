# Paragraph
# - Represents a block of content
#
# :kind         - 'Fe::Paragraph' for single table inheritance (STI)
# :content      - instructions, agreements, etc. to display
module Fe
  class Paragraph < Element
    validates_presence_of :content, on: :update
  end
end
