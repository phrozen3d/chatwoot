# frozen_string_literal: true

class SuperAdmin::Devise::SessionsController < Devise::SessionsController
  helper_method :microsoft_oauth_url

  def new
    self.resource = resource_class.new(sign_in_params)
  end

  def create
    redirect_to(super_admin_session_path, flash: { error: @error_message }) && return unless valid_credentials?

    sign_in(:super_admin, @super_admin)
    flash.discard
    redirect_to super_admin_users_path
  end

  def destroy
    sign_out
    flash.discard
    redirect_to '/'
  end

  private

  def valid_credentials?
    @super_admin = SuperAdmin.find_by!(email: params[:super_admin][:email])
    raise StandardError, 'Invalid Password' unless @super_admin.valid_password?(params[:super_admin][:password])

    true
  rescue StandardError => e
    Rails.logger.error e.message
    @error_message = 'Invalid credentials. Please try again.'
    false
  end

  def microsoft_oauth_url
    redirect_uri = ENV.fetch('MICROSOFT_OAUTH_CALLBACK_URL', nil)
    client_id = ENV.fetch('MICROSOFT_CLIENT_ID', nil)
    client_secret = ENV.fetch('MICROSOFT_CLIENT_SECRET', nil)
    tenant_id = ENV.fetch('MICROSOFT_TENANT_ID', nil)
    scope = 'User.Read openid email profile'

    "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/authorize?client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=code&response_mode=query&scope=#{scope}"
  end
end
