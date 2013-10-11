require 'spec_helper'

describe Element do 
  it { should belong_to :question_grid }  
  it { should belong_to :choice_field }  
  it { should have_many :page_elements }
  it { should have_many :pages }
end
