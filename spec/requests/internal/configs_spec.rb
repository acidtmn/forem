require "rails_helper"

RSpec.describe "/internal/config", type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:user, :super_admin) }

  describe "POST internal/events as a user" do
    before do
      sign_in(user)
    end

    it "bars the regular user to access" do
      expect { post "/internal/config", params: {} }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST internal/events" do
    before do
      sign_in(admin)
    end

    describe "staff" do
      it "updates staff_user_id" do
        post "/internal/config", params: { site_config: { staff_user_id: 2 } }
        expect(SiteConfig.staff_user_id).to eq(2)
      end

      it "updates default_site_email" do
        expected_email = "foo@bar.com"
        post "/internal/config", params: { site_config: { default_site_email: expected_email } }
        expect(SiteConfig.default_site_email).to eq(expected_email)
      end
    end

    describe "images" do
      it "updates main_social_image" do
        expected_image_url = "https://dummyimage.com/300x300"
        post "/internal/config", params: { site_config: { main_social_image: expected_image_url } }
        expect(SiteConfig.main_social_image).to eq(expected_image_url)
      end

      it "updates favicon_url" do
        expected_image_url = "https://dummyimage.com/300x300"
        post "/internal/config", params: { site_config: { favicon_url: expected_image_url } }
        expect(SiteConfig.favicon_url).to eq(expected_image_url)
      end

      it "updates logo_svg" do
        expected_image_url = "https://dummyimage.com/300x300"
        post "/internal/config", params: { site_config: { logo_svg: expected_image_url } }
        expect(SiteConfig.logo_svg).to eq(expected_image_url)
      end
    end

    describe "rate limits" do
      it "updates rate_limit_follow_count_daily" do
        post "/internal/config", params: { site_config: { rate_limit_follow_count_daily: 3 } }
        expect(SiteConfig.rate_limit_follow_count_daily).to eq(3)
      end
    end
  end
end
