class ReCaptcha
  include Devise::Controllers::Helpers

  def self.call(current_user = nil)
    new(current_user).call
  end

  def initialize(current_user)
    @current_user = current_user
  end

  def call
    self
  end

  def disabled?
    !enabled?
  end

  def enabled?
    # recaptcha will not be enabled if site key and secret key aren't set
    return false unless ReCaptcha.keys_configured?
    # recaptcha will always be enabled when not logged in
    return true if @current_user.nil?
    # recaptcha will not be enabled if current_user is auditable (trusted/admin)
    return false if @current_user.auditable?

    # recaptcha will be enabled if the user has a vomit or is too recent
    @current_user.vomitted_on? || @current_user.created_at > 1.month.ago
  end

  def self.keys_configured?
    SiteConfig.recaptcha_site_key.present? && SiteConfig.recaptcha_secret_key.present?
  end

  def self.for_registration_disabled?
    !ReCaptcha.for_registration_enabled?
  end

  def self.for_registration_enabled?
    ReCaptcha.keys_configured? && SiteConfig.require_captcha_for_email_password_registration
  end
end
