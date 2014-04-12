require "active_model/password_reset/version"
require "active_model/password_reset/error"
require "active_model"

module ActiveModel
  class PasswordReset
    EXPIRATION_TIME = 60 * 60 * 24 # 24 hours

    include Model

    attr_reader :email
    attr_writer :user

    validates :email, presence: true
    validate :existence, if: -> { email.present? }
    delegate :id, to: :user, prefix: true, allow_nil: true

    def email=(email)
      remove_instance_variable(:@user) if defined?(@user)
      @email = email
    end

    def user
      return @user if defined?(@user)
      @user = User.find_by(email: email)
    end

    def token
      email = user.email
      digest = Digest::MD5.digest(user.password_digest)
      expires_at = Time.now.to_i + EXPIRATION_TIME
      self.class.generate_token([email, digest, expires_at])
    end

    def self.find(token)
      email, digest, expires_at = verify_token(token)
      raise TokenExpired if Time.now.to_i > expires_at.to_i
      new(email: email).tap do |password_reset|
        raise EmailInvalid if password_reset.invalid?
        raise PasswordChanged if password_reset.send(:digest) != digest
      end
    end

    private

    def self.message_verifier
      Rails.application.message_verifier("password reset salt")
    end

    def self.generate_token(*args)
      Base64.urlsafe_encode64(message_verifier.generate(*args))
    end

    def self.verify_token(string)
      message_verifier.verify(Base64.urlsafe_decode64(string))
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
      raise TokenInvalid
    end

    def digest
      Digest::MD5.digest(user.password_digest)
    end

    def existence
      errors.add(:email, :invalid) if user.blank?
    end
  end
end
