require "qe/engine"

module Qe
  def self.next_label(prefix, labels)
    max = labels.inject(0) do |m, label|
      num = label[/^#{prefix} ([0-9]+)$/i, 1].to_i   # extract your digits
      num > m ? num : m
    end

    "#{prefix} #{max.next}"
  end
end
