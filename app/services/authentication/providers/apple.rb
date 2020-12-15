module Authentication
  module Providers
    # Apple authentication provider, uses omniauth-apple as backend
    class Apple < Provider
      OFFICIAL_NAME = "Apple".freeze
      SETTINGS_URL = "https://appleid.apple.com/account/manage".freeze
      TRUSTED_CALLBACK_ORIGIN = "https://appleid.apple.com".freeze
      CALLBACK_PATH = "/users/auth/apple/callback".freeze

      # Currently `beta` state until thoroughly tested in production level env
      def self.beta_access?
        !Flipper.enabled?(:apple_auth)
      end

      def new_user_data
        # Apple sends `first_name` and `last_name` as separate fields
        name = "#{info.first_name} #{info.last_name}"
        timestamp = raw_info.auth_time || raw_info.id_info.auth_time
        image_url = if Rails.env.test?
                      SiteConfig.mascot_image_url
                    else
                      Users::ProfileImageGenerator.call
                    end

        {
          email: info.email,
          apple_created_at: Time.zone.at(timestamp),
          apple_username: user_nickname,
          name: name,
          remote_profile_image_url: image_url
        }
      end

      def existing_user_data
        # Apple by default will send nil `first_name` and `last_name` after
        # the first login. To cover the case where a user disconnects their
        # Apple authorization, signs in again and then changes their name,
        # we update the username only if the name is not nil
        apple_username = info.first_name.present? ? info.first_name.downcase : nil
        timestamp = raw_info.auth_time || raw_info.id_info.auth_time

        data = { apple_created_at: Time.zone.at(timestamp) }
        data[:apple_username] = apple_username if apple_username
        data
      end

      # For Apple we override this method because the `info` payload doesn't
      # include `nickname`. On top of not having a username, Apple allows users
      # to 'choose' the first_name & last_name sent our way so they are
      # definitely not assured to be unique. We still need `user_nickname` to
      # always be the same on each login so we use the email hash as suffix to
      # avoid collisions with other registrations with the same first_name
      def user_nickname
        [
          info.first_name&.downcase,
          info.last_name&.downcase,
          Digest::SHA512.hexdigest(info.email),
        ].join("_")[0...25]
      end

      def self.official_name
        OFFICIAL_NAME
      end

      def self.settings_url
        SETTINGS_URL
      end

      def self.sign_in_path(**kwargs)
        ::Authentication::Paths.sign_in_path(
          provider_name,
          **kwargs,
        )
      end

      protected

      def cleanup_payload(auth_payload)
        auth_payload
      end
    end
  end
end
