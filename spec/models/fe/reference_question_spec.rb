require 'rails_helper' 

describe Fe::ReferenceQuestion do
  describe '#ptemplate' do 
    it 'default' do 
      ref = create(:reference_question)
      expect(ref.style).to eq("peer")
      expect(ref.ptemplate).to eq("fe/reference_peer")
    end
    
    it 'customized' do 
      ref = create(:reference_question)
      ref.style = "abc"
      expect(ref.ptemplate).to eq("fe/reference_abc")
    end
  end

  it 'resets the question_sheet_id for references not created' do
    qs1 = create(:question_sheet)
    reference_question = create(:reference_question, related_question_sheet_id: qs1.id)
    reference_sheet = create(:reference_sheet, question: reference_question)
    expect(reference_sheet.question_sheet_id).to eq(qs1.id)

    # change question sheet on ref element, the reference_sheet's question sheet should change
    qs2 = create(:question_sheet)
    expect(reference_sheet.status).to eq('created')
    reference_question.update_attribute(:related_question_sheet_id, qs2.id)
    expect(reference_sheet.reload.question_sheet_id).to eq(qs2.id)

    # start the reference, then change question sheet on ref element, 
    # the reference_sheet's question sheet should not change
    reference_sheet.update_attribute(:status, 'started')
    qs3 = create(:question_sheet)
    reference_question.update_attribute(:related_question_sheet_id, qs3.id)
    expect(reference_sheet.reload.question_sheet_id).to eq(qs2.id)
  end
end
