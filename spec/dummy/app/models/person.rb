class Person < Fe::Person
  belongs_to :user
  has_many   :applications, class_name: Fe.answer_sheet_class, foreign_key: :applicant_id

  def application
    applications.first
  end
  def application=(val)
    applications << val unless applications.include?(val)
  end
end
