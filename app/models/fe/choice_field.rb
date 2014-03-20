# ChoiceField
# - a question that allows the selection of one or more choices
module Fe
  class ChoiceField < Question
    include ChoiceFieldConcern
  end
end