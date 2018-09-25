require "rails_helper"

RSpec.describe "UserSettings", type: :request do
  let(:user) { create(:user) }

  describe "GET /settings/:tab" do
    context "when not signed-in" do
      it "redirects them to login" do
        get "/settings"
        expect(response).to redirect_to("/enter")
      end
    end

    context "when signed-in" do
      before { login_as user }

      it "renders various settings tabs properly" do
        %w[organization switch-organizations billing misc account].each do |tab|
          get "/settings/#{tab}"
          expect(response.body).to include("Settings for")
        end
      end

      it "doesn't let user access membership if user has no monthly_dues" do
        get "/settings/membership"
        expect(response.body).not_to include("Settings for")
      end

      it "allows user with monthly_dues to access membership" do
        user.update_column(:monthly_dues, 5)
        get "/settings/membership"
        expect(response.body).to include("Settings for")
      end

      it "allows users to visit the account page" do
        get "/settings/account"
        expect(response.body).to include("Danger Zone")
      end
    end
  end

  describe "PUT /update/:id" do
    before { login_as user }

    it "updates summary" do
      put "/users/#{user.id}", params: { user: { tab: "profile", summary: "Hello new summary" } }
      expect(user.summary).to eq("Hello new summary")
    end

    it "updates username to too short username" do
      put "/users/#{user.id}", params: { user: { tab: "profile", username: "h" } }
      expect(response.body).to include("Username is too short")
    end
  end

  describe "DELETE /users/remove_association" do
    context "when user has two identities" do
      let(:user) { create(:user, :two_identities) }

      before { login_as user }

      it "allows the user to remove an identity" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.identities.count).to eq 1
      end

      it "removes the correct identity" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.identities.first.provider).to eq "github"
      end

      it "removes their associated username" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(user.twitter_username).to eq nil
      end

      it "redirects successfully to /settings/account" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(response).to redirect_to "/settings/account"
      end

      it "renders a successful response message" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(flash[:notice]).to eq "Your Twitter account was successfully removed."
      end

      it "does not show the Remove OAuth section afterward" do
        delete "/users/remove_association", params: { provider: "twitter" }
        expect(response.body).not_to include "Remove OAuth Associations"
      end
    end

    # Users won't be able to do this via the view, but in case they hit the route somehow...
    context "when user has only one identity" do
      let(:user) { create(:user) }

      before { login_as user }

      it "sets the proper error message" do
        delete "/users/remove_association", params: { provider: "github" }
        expect(flash[:error]).
          to eq "An error occurred. Please try again or send an email to: yo@dev.to"
      end

      it "does not delete any identities" do
        original_identity_count = user.identities.count
        delete "/users/remove_association", params: { provider: "github" }
        expect(user.identities.count).to eq original_identity_count
      end

      it "redirects successfully to /settings/account" do
        delete "/users/remove_association", params: { provider: "github" }
        expect(response).to redirect_to "/settings/account"
      end
    end
  end
end
