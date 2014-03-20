require 'spec_helper'

describe Fe::QuestionSheet do
  it { should have_many :pages }
  it { should have_many :answer_sheets }
  it { should validate_presence_of :label }
  it { should validate_uniqueness_of :label }
end
