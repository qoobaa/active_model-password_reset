# ActiveModel::PasswordReset

`ActiveModel::PasswordReset` is a lightweight password reset model implemented on top of `ActiveModel::Model`. It does not require storing any additional information in the database. Resulting token is signed by `ActiveSupport::MessageVerifier` class, using `secret_key_base` and salt. Token is invalidated when:

* user changed password
* expiration time passed (default: 24 hours)

## Installation

Add this line to your application's Gemfile:

    gem "active_model-password_reset"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_model-password_reset

## Usage

The most popular workflow is:

    class PasswordResetsController < ApplicationController
      def new
        @password_reset = ActiveModel::PasswordReset.new
      end

      def create
        @password_reset = ActiveModel::PasswordReset.new(password_reset_params)
        if @password_reset.valid?
          UserMailer.reset_password(password_reset.email, password_reset.token).deliver
          redirect_to root_url, notice: "You will receive an email with instructions."
        else
          render :new
        end
      end

      private

      def password_reset_params
        params.require(:active_model_password_reset).permit(:email)
      end
    end

    class PasswordsController < ApplicationController
      def edit
        # find raises TokenInvalid, TokenExpired, EmailInvalid, PasswordChanged exceptions
        @password_reset = ActiveModel::PasswordReset.find(params[:id])
        @user = @password_reset.user
      rescue ActiveModel::PasswordReset::Error
        raise ActiveRecord::RecordNotFound # display 404
      end

      def update
        @password_reset = ActiveModel::PasswordReset.find(params[:id])
        @user = @password_reset.user
        if @user.update(user_params)
          redirect_to root_url, notice: "Password changed successfully, you can now log in."
        else
          render :edit
        end
      rescue ActiveModel::PasswordReset::Error
        raise ActiveRecord::RecordNotFound # display 404
      end

      private

      def user_params
        params.require(:user).permit(:password, :password_confirmation)
      end
    end

If you don't like the default behavior, you can always inherit the session model and override some defaults:

    class PasswordReset < ActiveModel::PasswordReset
      EXPIRATION_TIME = 1.hour

      def email=(email)
        @email = email
        @user = Admin.find_by(email: email)
      end
    end

## Copyright

Copyright © 2014 Kuba Kuźma. See LICENSE for details.
