class Fe::CurrentAddress < Fe::Address

  def save(*)
    self.address_type = "current"
    super
  end

  def save!(*)
    self.address_type = "current"
    super
  end
end
