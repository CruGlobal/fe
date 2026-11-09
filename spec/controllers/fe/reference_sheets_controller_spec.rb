require 'rails_helper'

describe Fe::ReferenceSheetsController, type: :controller do
  it 'renders not_found for a wrong access key without asking the host' do
    reference_sheet = create(:reference_sheet)
    expect(controller).not_to receive(:fe_can_use_answer_sheet?)

    get :edit, params: {id: reference_sheet.id, a: 'wrong'}

    expect(response).to render_template('fe/reference_sheets/not_found')
  end
end
