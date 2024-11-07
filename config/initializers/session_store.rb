# Be sure to restart your server when you modify this file.

# we want a default in case the expiration is not set or set to 0
# because 0 is an invalid value
app_config_expires_after = ApplicationConfig["SESSION_EXPIRY_SECONDS"].to_i
expires_after = app_config_expires_after.positive? ? app_config_expires_after : 2.weeks.to_i

# See https://github.com/redis-store/redis-rails#session-storage for configuration options
servers = ApplicationConfig["REDIS_SESSIONS_URL"] || ApplicationConfig["REDIS_URL"]

domain = Rails.env.production? ? ApplicationConfig["APP_DOMAIN"] : nil

# Domain property should only be set in production
domain_lambda = lambda do |request|
  if Rails.env.production?
    # List of your secondary domains
    secondary_domains = ApplicationConfig["SECONDARY_APP_DOMAINS"].to_s.split(",").map(&:strip)
    if secondary_domains.include?(request.host)
      # For secondary domains, set domain to nil (cookie for current domain)
      nil
    else
      # For main domain, set to ApplicationConfig["APP_DOMAIN"]
      ApplicationConfig["APP_DOMAIN"]
    end
  else
    # In non-production environments, don't set the domain
    nil
  end
end

# Main session store
Rails.application.config.session_store :redis_store,
                                       key: ApplicationConfig["SESSION_KEY"],
                                       domain: domain_lambda,
                                       servers: servers,
                                       expire_after: expires_after,
                                       secure: ApplicationConfig["FORCE_SSL_IN_RAILS"] == "true",
                                       same_site: :lax,
                                       httponly: true

# iFrame session store options
Rails.application.config.iframe_session_options = {
  key: "_iframe_session",
  domain: domain,
  servers: servers,
  expire_after: 48.hours.to_i, # Shorter expiration time for the iFrame session
  secure: ApplicationConfig["FORCE_SSL_IN_RAILS"] == "true",
  same_site: :none,
  httponly: true,
  path: "/auth_pass" # Limit the cookie to the /auth_pass path
}
