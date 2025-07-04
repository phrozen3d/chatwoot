module Auth
  class MicrosoftOauthController < ApplicationController
    include EmailHelper
    require 'net/http'
    require 'uri'
    require 'json'

    def callback
      code = params[:code]
      ENV.fetch('FRONTEND_URL', nil)
      redirect_uri = ENV.fetch('MICROSOFT_OAUTH_CALLBACK_URL', nil)
      client_id = ENV.fetch('MICROSOFT_CLIENT_ID', nil)
      client_secret = ENV.fetch('MICROSOFT_CLIENT_SECRET', nil)
      tenant_id = ENV.fetch('MICROSOFT_TENANT_ID', nil)

      # Step 1: Exchange code for token
      token_uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
      token_response = Net::HTTP.post_form(token_uri, {
        'client_id' => client_id,
        'client_secret' => client_secret,
        'grant_type' => 'authorization_code',
        'code' => code,
        'redirect_uri' => redirect_uri,
        'scope' => 'User.Read openid email profile'
      })

      token_data = JSON.parse(token_response.body)
      access_token = token_data['access_token']
      puts "token_response"
      unless access_token
        Rails.logger.error "Microsoft OAuth failed: #{token_data}"
        return redirect_to login_url(error: 'invalid-microsoft-oauth')
      end

      # Step 2: Get user info
      profile_uri = URI("https://graph.microsoft.com/v1.0/me")
      profile_request = Net::HTTP::Get.new(profile_uri)
      profile_request['Authorization'] = "Bearer #{access_token}"

      profile_response = Net::HTTP.start(profile_uri.hostname, profile_uri.port, use_ssl: true) do |http|
        http.request(profile_request)
      end

      user_info = JSON.parse(profile_response.body)

      email = user_info['mail'] || user_info['userPrincipalName']
      name = user_info['displayName']

      if email.blank?
        return redirect_to login_url(error: 'no-email-returned')
      end

      # Step 3: Sign in or sign up
      user = User.find_by(email: email.downcase)

      if user.nil?
        begin
          Rails.logger.info "Microsoft user info: #{user_info.to_json}"
        rescue => e
          Rails.logger.error "Failed to log user_info: #{e.message}"
        end

        @resource, @account = AccountBuilder.new(
          account_name: extract_domain_without_tld(email),
          user_full_name: name,
          email: email.downcase,
          locale: I18n.locale,
          confirmed: true,
        ).perform

        # Step 4: Redirect with SSO token
        sso_token = @resource.generate_sso_auth_token
        redirect_to login_url(email: email.downcase, sso_auth_token: sso_token)
      else
        # Step 4: Redirect with SSO token
        sso_token = user.generate_sso_auth_token
        redirect_to login_url(email: user.email, sso_auth_token: sso_token)
      end
    end

    def admin_callback
      code = params[:code]
      ENV.fetch('FRONTEND_URL', nil)
      redirect_uri = ENV.fetch('MICROSOFT_OAUTH_ADMIN_CALLBACK_URL', nil)
      client_id = ENV.fetch('MICROSOFT_CLIENT_ID', nil)
      client_secret = ENV.fetch('MICROSOFT_CLIENT_SECRET', nil)
      tenant_id = ENV.fetch('MICROSOFT_TENANT_ID', nil)

      # Step 1: Exchange code for token
      token_uri = URI("https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token")
      token_response = Net::HTTP.post_form(token_uri, {
        'client_id' => client_id,
        'client_secret' => client_secret,
        'grant_type' => 'authorization_code',
        'code' => code,
        'redirect_uri' => redirect_uri,
        'scope' => 'User.Read openid email profile'
      })

      token_data = JSON.parse(token_response.body)
      access_token = token_data['access_token']

      unless access_token
        Rails.logger.error "Microsoft OAuth failed: #{token_data}"
        return redirect_to(super_admin_session_path, flash: { error: "Microsoft OAuth failed" })
      end

      # Step 2: Get user info
      profile_uri = URI("https://graph.microsoft.com/v1.0/me")
      profile_request = Net::HTTP::Get.new(profile_uri)
      profile_request['Authorization'] = "Bearer #{access_token}"

      profile_response = Net::HTTP.start(profile_uri.hostname, profile_uri.port, use_ssl: true) do |http|
        http.request(profile_request)
      end

      user_info = JSON.parse(profile_response.body)

      email = user_info['mail'] || user_info['userPrincipalName']
      name = user_info['displayName']

      if email.blank?
        return redirect_to(super_admin_session_path, flash: { error: "Microsoft OAuth failed" })
      end


      redirect_to(super_admin_session_path, flash: { error: @error_message }) && return unless valid_admin_credentials?(email)

      sign_in(:super_admin, @super_admin)
      flash.discard
      redirect_to super_admin_users_path

      # user = User.find_by(email: email, type: 'SuperAdmin')

      # if user
      #   sign_in(user)
      #   flash.discard
      #   return redirect_to super_admin_users_path
      # else
      #   return redirect_to(super_admin_session_path, flash: { error: "Not super admin user." })
      # end
    end

    private

    def login_url(email: nil, sso_auth_token: nil, error: nil)
      frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
      params = { email: email, sso_auth_token: sso_auth_token, error: error }.compact
      "#{frontend_url}/app/login?#{params.to_query}"
    end

    def signup_enabled?
      GlobalConfigService.load('ENABLE_ACCOUNT_SIGNUP', 'false') != 'false'
    end

    def valid_admin_credentials?(email)
      @super_admin = SuperAdmin.find_by!(email: email.downcase)
      raise StandardError, 'Admin not found' if @super_admin.nil?

      true
    rescue StandardError => e
      Rails.logger.error e.message
      @error_message = 'Invalid credentials. Please try again.'
      false
    end
  end
end
