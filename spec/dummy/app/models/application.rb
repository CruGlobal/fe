class Application < Fe::Application
  belongs_to :applicant, class_name: "Person"
end
