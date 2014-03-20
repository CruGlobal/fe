require 'spec_helper'

describe Fe::PageElement do
  it { should belong_to :page }
  it { should belong_to :element }
end
