require "test/unit"
require "active_model/password_reset"
require "ostruct"

class Rails
  def self.application
    OpenStruct.new(secrets: OpenStruct.new(secret_key_base: "12345678901234567890123456789012345678901234567890123456789012345678901234567890"))
  end
end
