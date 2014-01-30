module ActiveModel
  class PasswordReset
    class Error < StandardError; end
    class EmailInvalid < Error; end
    class TokenInvalid < Error; end
    class TokenExpired < Error; end
    class PasswordChanged < Error; end
  end
end
