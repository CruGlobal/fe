require 'rails_helper'

describe Fe::Element do
  it { expect belong_to :question_grid }  
  it { expect belong_to :choice_field }  
  it { expect have_many :page_elements }
  it { expect have_many :pages }
  it { expect validate_presence_of :kind }
  # it { expect validate_presence_of :style } # this isn't working
  it { expect ensure_length_of :kind }
  it { expect ensure_length_of :style }
end
