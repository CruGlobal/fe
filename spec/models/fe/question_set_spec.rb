require 'rails_helper'

describe Fe::QuestionSet do
  let(:app) { create(:application) }

  before do
    answer_sheet = create(:answer_sheet)
    page = create(:page)
    @el_confidential = create(:text_field_element, label: 'conf1', is_confidential: true, share: true)
    @el_visible = create(:text_field_element, label: 'vis1', is_confidential: false, share: false)
    @el_confidential2 = create(:text_field_element, label: 'conf2', is_confidential: true, share: true)
    @el_visible2 = create(:text_field_element, label: 'vis2', is_confidential: false, share: true)
    page.elements << @el_confidential << @el_visible << @el_confidential2 << @el_visible2
    @question_set = Fe::QuestionSet.new(page.elements, app)
  end

  it 'should filter default show' do
    # filter out confidential questions and questions with share flag (the share flag would likely
    # never be used to filter, but just to test that it will only filter those that match all the
    # filter methods)
    @question_set.set_filter(filter_default: :show, filter: [ :is_confidential, :share ])
    expect(@question_set.elements).to eq([@el_visible, @el_visible2])
  end

  it 'should filter default hide' do
    # show only confidential questions and questions with share flag (the share flag would likely
    # never be used to filter, but just to test that it will only filter those that match all the
    # filter methods)
    @question_set.set_filter(filter_default: :hide, filter: [ :is_confidential, :share ])
    expect(@question_set.elements).to eq([@el_confidential, @el_confidential2])
  end
end
