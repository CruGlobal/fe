require 'rails_helper'

describe Fe::Element do
  it { should belong_to :question_grid }  
  it { should belong_to :choice_field }  
  it { should have_many :page_elements }
  it { should have_many :pages }
  it { should validate_presence_of :kind }
  # it { should validate_presence_of :style } # this isn't working
  it { should ensure_length_of :kind }
  it { should ensure_length_of :style }
end
