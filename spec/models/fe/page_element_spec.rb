require 'rails_helper'

describe Fe::PageElement do
  it { expect belong_to :page }
  it { expect belong_to :element }
end
