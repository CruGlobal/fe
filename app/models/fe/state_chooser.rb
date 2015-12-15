require 'carmen'
# State Dropdown
# - drop down of states
module Fe
  class StateChooser < Question
    def choices(country = 'US')
      country = 'US' unless country.present?
      @states = Carmen.states(country)
    end
  end
end
