require 'spec_helper'

describe PageElement do 
  it { should belong_to :page }
  it { should belong_to :element }
end
