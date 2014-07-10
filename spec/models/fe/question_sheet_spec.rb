require 'rails_helper'

describe Fe::QuestionSheet do
  it { expect have_many :pages }
  it { expect have_many :answer_sheets }
  it { expect validate_presence_of :label }
  it { expect validate_uniqueness_of :label }
end
