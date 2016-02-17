require "rails_helper"

RSpec.describe Fe::UpdateReferenceSheetVisibilityJob, type: :job do
  it "matches with enqueued job" do
    expect {
      Fe::UpdateReferenceSheetVisibilityJob.perform_later(create(:application), [1])
    }.to have_enqueued_job(Fe::UpdateReferenceSheetVisibilityJob)
  end

  context '#perform' do
    let(:qs) { create(:question_sheet_with_pages) }
    let(:qs2) { create(:question_sheet_with_pages) }
    let(:p) { qs.pages.first }
    let(:p2) { qs.pages.first }
    let(:ref_el) { create(:reference_element) }
    let(:ref_el2) { create(:reference_element) }
    let(:ref_el3) { create(:reference_element) }
    let(:app) { create(:application) }
    let(:affecting_el) { create(:text_field_element) }

    before do
      p.elements << ref_el
      p2.elements << ref_el2
      app.question_sheets << qs << qs2
    end

    it "calls update_visible for all refs whose visibility_affecting_element_ids include the answer's question" do
      expect(app).to receive(:question_sheets_all_reference_elements).and_return([ref_el, ref_el2])
      expect(ref_el).to receive(:visibility_affecting_element_ids).and_return([affecting_el.id])
      expect(ref_el).to receive(:update_visible)
      ref_el_arr = [ref_el]
      allow(app).to receive(:all_references).and_return(ref_el_arr)
      allow(ref_el_arr).to receive(:where).with(question_id: ref_el.id).and_return(ref_el_arr)
      expect(ref_el2).to receive(:visibility_affecting_element_ids).and_return([])
      qs = Fe::QuestionSet.new([affecting_el], app)
      puts app.object_id
      Fe::UpdateReferenceSheetVisibilityJob.new.perform(app, qs.questions.collect(&:id))
    end
  end
end
