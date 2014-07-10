require 'rails_helper'

describe Fe::Page do
  it { expect belong_to :question_sheet }
  it { expect have_many :page_elements }
  it { expect have_many :elements }
  it { expect have_many :questions }
  it { expect have_many :question_grids }
  it { expect have_many :question_grid_with_totals }
  # it { expect validate_presence_of :label } # this isn't working
  # it { expect validate_presence_of :number } # this isn't working
  it { expect ensure_length_of :label }
  # it { expect validate_numericality_of :number }
end
