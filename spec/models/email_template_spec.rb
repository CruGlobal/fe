require 'spec_helper'

describe EmailTemplate do 
  it { should validate_presence_of :name }
end
