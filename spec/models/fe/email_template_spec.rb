require 'rails_helper'

describe Fe::EmailTemplate do
  it { expect validate_presence_of :name }
end
