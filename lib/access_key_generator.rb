require 'securerandom'

module Fe
  module AccessKeyGenerator
    def generate_access_key
      begin
        self.access_key = SecureRandom.hex
      end while self.class.exists?(access_key: access_key)
      return access_key
    end
  end
end
