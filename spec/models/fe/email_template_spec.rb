require 'rails_helper'

describe Fe::EmailTemplate, type: :model do
  it { expect validate_presence_of :name }
end
