require "test_helper"

class User
  attr_accessor :id, :password_digest, :email

  RECORDS = {
    {email: "alice@example.com"} => {id: 1, email: "alice@example.com", password_digest: "alicedigest"}
  }

  def self.find_by(options)
    attributes = RECORDS[options]
    new(attributes) if attributes.present?
  end

  def initialize(options)
    self.id              = options[:id]
    self.email           = options[:email]
    self.password_digest = options[:password_digest]
  end
end

class PasswordResetTest < Test::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = @password_reset = ActiveModel::PasswordReset.new
  end

  def test_basic_workflow
    @password_reset.email = "alice@example.com"
    @password_reset.valid?
    token = @password_reset.token
    assert token.present?
    password_reset = ActiveModel::PasswordReset.find(token)
    assert_equal @password_reset.email, password_reset.email
    assert password_reset.user.present?
  end

  def test_is_invalid_with_invalid_email
    @password_reset.email = "invalid@example.com"
    assert @password_reset.invalid?
    assert @password_reset.errors[:email].present?
  end

  def test_is_invalid_without_email
    @password_reset.email = nil
    assert @password_reset.invalid?
    assert @password_reset.errors[:email].present?
  end

  def test_find_raises_exception_with_invalid_email
    token = ActiveModel::PasswordReset::MessageVerifier.generate(["invalid@example.com", Digest::MD5.digest("alicedigest"), Time.now.to_i + 3600])
    assert_raises(ActiveModel::PasswordReset::EmailInvalid) { ActiveModel::PasswordReset.find(token) }
  end

  def test_find_raises_exception_with_invalid_token
    assert_raises(ActiveModel::PasswordReset::TokenInvalid) { ActiveModel::PasswordReset.find("invalidtoken") }
  end

  def test_find_raises_exception_with_expired_token
    token = ActiveModel::PasswordReset::MessageVerifier.generate(["alice@example.com", Digest::MD5.digest("alicedigest"), Time.now.to_i - 3600])
    assert_raises(ActiveModel::PasswordReset::TokenExpired) { ActiveModel::PasswordReset.find(token) }
  end

  def test_find_raises_exception_with_changed_password
    token = ActiveModel::PasswordReset::MessageVerifier.generate(["alice@example.com", Digest::MD5.digest("anotheralicedigest"), Time.now.to_i + 3600])
    assert_raises(ActiveModel::PasswordReset::PasswordChanged) { ActiveModel::PasswordReset.find(token) }
  end
end
