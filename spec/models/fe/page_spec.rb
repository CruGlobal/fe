require 'spec_helper'

describe Fe::Page do
  it { should belong_to :question_sheet }
  it { should have_many :page_elements }
  it { should have_many :elements }
  it { should have_many :questions }
  it { should have_many :question_grids }
  it { should have_many :question_grid_with_totals }
  # it { should validate_presence_of :label } # this isn't working
  # it { should validate_presence_of :number } # this isn't working
  it { should ensure_length_of :label }
  # it { should validate_numericality_of :number }
end
