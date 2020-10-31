require "rails_helper"

RSpec.describe AuthenticationHelper, type: :helper do
  let(:user) { create(:user, :with_identity) }

  before do
    omniauth_mock_providers_payload
  end

  describe "#authentication_enabled_providers_for_user" do
    it "returns an enabled provider" do
      provider = Authentication::Providers.available.first
      allow(Authentication::Providers).to receive(:enabled).and_return([provider])
      allow(user).to receive(:identities).and_return(user.identities.where(provider: provider))

      expected_result = Authentication::Providers.get!(provider)
      expect(helper.authentication_enabled_providers_for_user(user)).to match_array([expected_result])
    end

    it "does not return a disabled provider" do
      disabled_provider = %i[github]
      providers = Authentication::Providers.available - disabled_provider
      allow(Authentication::Providers).to receive(:enabled).and_return(providers)
      user = create(:user, :with_identity)

      provider_names = helper.authentication_enabled_providers_for_user(user).map(&:provider_name)
      expect(provider_names).not_to include(disabled_provider)
    end
  end

  describe "#recaptcha_configured_and_enabled?" do
    context "when recaptcha is enabled" do
      before do
        allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "returns true if both site & secret keys present" do
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("someSiteKey")

        expect(recaptcha_configured_and_enabled?).to be(true)
      end

      it "returns false if site or secret key missing" do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("")

        expect(recaptcha_configured_and_enabled?).to be(false)
      end
    end

    it "returns false if recaptcha disabled for email signup" do
      allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(false)

      expect(recaptcha_configured_and_enabled?).to be(false)
    end
  end

  describe "tooltip classes, attributes and content" do
    context "when invite-only-mode enabled and no enabled auth providers" do
      before do
        allow(SiteConfig).to receive(:invite_only_mode).and_return(true)
        allow(SiteConfig).to receive(:authentication_providers).and_return([])
      end

      it "returns 'crayons-tooltip' class for relevant helpers" do
        expect(auth_provider_enable_btn_tooltip_class).to eq("crayons-tooltip")
        expect(email_auth_disable_btn_tooltip_class).to eq("crayons-tooltip")
      end

      it "returns 'disabled' attribute for relevant helper" do
        expect(auth_provider_enable_btn_disable_class).to eq("disabled")
        expect(email_auth_disable_btn_disable_class).to eq("disabled")
      end

      it "returns appropriate text for 'enable_disable_btn_tooltip_text' helper" do
        invite_only_mode_warning = "You cannot do this until you disable Invite Only Mode"
        only_one_auth_method_warning = "You cannot do this until you enable at least one other registration option"

        expect(enable_disable_btn_tooltip_text).to eq(invite_only_mode_warning)

        allow(SiteConfig).to receive(:invite_only_mode).and_return(false)

        expect(enable_disable_btn_tooltip_text).to eq(only_one_auth_method_warning)
      end
    end

    context "when email login enabled and one enabled auth provider" do
      before do
        allow(SiteConfig).to receive(:allow_email_password_login).and_return(false)
        allow(SiteConfig).to receive(:authentication_providers).and_return(["facebook"])
      end

      it "returns 'crayons-tooltip' class for relevant helpers" do
        expect(auth_provider_disable_btn_tooltip_class).to eq("crayons-tooltip")
      end

      it "returns 'disabled' attribute for relevant helper" do
        expect(auth_provider_disable_btn_disable_class).to eq("disabled")
      end

      it "returns appropriate text for 'enable_disable_btn_tooltip_text' helper" do
        only_one_auth_method_warning = "You cannot do this until you enable at least one other registration option"

        expect(enable_disable_btn_tooltip_text).to eq(only_one_auth_method_warning)
      end
    end
  end
end
