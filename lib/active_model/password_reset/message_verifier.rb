require "singleton"

module ActiveModel
  class PasswordReset
    class MessageVerifier
      include Singleton

      attr_reader :message_verifier

      class << self
        def generate(object)
          instance.message_verifier.generate(object)
        end

        def verify(string)
          instance.message_verifier.verify(string)
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          raise TokenInvalid
        end
      end

      def initialize
        key_generator = ActiveSupport::KeyGenerator.new(Rails.application.config.secret_key_base, iterations: 1000)
        secret = key_generator.generate_key("password reset salt")
        @message_verifier = ActiveSupport::MessageVerifier.new(secret)
      end
    end
  end
end
