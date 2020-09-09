# This change takes the Devise remember_cookie_values and explicitely assigns the admin-defined domain

module Devise
  module Controllers
    module Rememberable
      def remember_cookie_values(resource)
        options = { httponly: true }
        options.merge!(forget_cookie_values(resource))
        options.merge!(
          value: resource.class.serialize_into_cookie(resource),
          expires: resource.remember_expires_at,
          domain: ".#{SiteConfig.app_domain}",
        )
      end

      def self.cookie_values
        # Default: Rails.configuration.session_options.slice(:path, :domain, :secure)
        { domain: ".#{SiteConfig.app_domain}", secure: ApplicationConfig["FORCE_SSL_IN_RAILS"] == "true" }
      end
    end
  end
end
