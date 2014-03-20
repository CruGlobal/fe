require 'spec_helper'

describe Fe::EmailTemplate do
  it { should validate_presence_of :name }
end
