require 'carmen'
# State Dropdown
# - drop down of states
module Fe
  class StateChooser < Question
    def choices(country = 'US')
      @states = Carmen.states(country)
    end
  end
end