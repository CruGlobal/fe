require 'carmen'
# State Dropdown
# - drop down of states
module Fe
  class StateChooser < Question
    def choices(locale = nil, country = 'US')
      @states = _(Carmen.states(country))
    end
  end
end
