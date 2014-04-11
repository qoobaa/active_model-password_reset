require "singleton"

module ActiveModel
  class PasswordReset
    class MessageVerifier
      include Singleton

      attr_reader :message_verifier

      class << self
        def generate(object)
          token = instance.message_verifier.generate(object)
          Base64.urlsafe_encode64(token)
        end

        def verify(string)
          token = Base64.urlsafe_decode64(string)
          instance.message_verifier.verify(token)
        rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
          raise TokenInvalid
        end
      end

      def initialize
        key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secrets.secret_key_base, iterations: 1000)
        secret = key_generator.generate_key("password reset salt")
        @message_verifier = ActiveSupport::MessageVerifier.new(secret)
      end
    end
  end
end
