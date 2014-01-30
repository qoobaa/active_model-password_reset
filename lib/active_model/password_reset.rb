require "active_model/password_reset/version"
require "active_model/password_reset/error"
require "active_model/password_reset/message_verifier"
require "active_model"

module ActiveModel
  class PasswordReset
    EXPIRATION_TIME = 60 * 60 * 24 # 24 hours

    include Model

    attr_accessor :email

    validates :email, presence: true
    validate :existence, if: -> { email.present? }
    delegate :id, to: :user, prefix: true, allow_nil: true

    def user
      return @user if defined?(@user)
      @user = User.find_by(email: email)
    end

    def token
      email = user.email
      digest = Digest::MD5.digest(user.password_digest)
      expires_at = Time.now.to_i + EXPIRATION_TIME
      MessageVerifier.generate([email, digest, expires_at])
    end

    def self.find(token)
      email, digest, expires_at = MessageVerifier.verify(token)
      raise TokenExpired if Time.now.to_i > expires_at.to_i
      new(email: email).tap do |password_reset|
        raise EmailInvalid if password_reset.invalid?
        raise PasswordChanged if password_reset.send(:digest) != digest
      end
    end

    private

    def digest
      Digest::MD5.digest(user.password_digest)
    end

    def existence
      errors.add(:email, :invalid) if user.blank?
    end
  end
end
