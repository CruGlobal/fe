class Fe::Application < ActiveRecord::Base
  belongs_to :person
  belongs_to :fe_apply, :class_name => "Fe::Apply", :foreign_key => "apply_id"

  def find_or_create_apply()
    if self.fe_apply.nil?
      create_apply
    end
    self.fe_apply
  end

protected

  def create_apply
    #self.dateAppStarted = Time.now # TODO
    self.fe_apply ||= Fe::Apply.create(:applicant_id => self.person.id)
  end

end
