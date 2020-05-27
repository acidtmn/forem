require "rails_helper"

RSpec.describe "UserProfiles", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe "GET /user" do
    xit "renders to appropriate page" do
      get "/#{user.username}"
      expect(response.body).to include CGI.escapeHTML(user.name)
    end

    xit "renders pins if any" do
      create(:article, user_id: user.id)
      create(:article, user_id: user.id)
      last_article = create(:article, user_id: user.id)
      create(:profile_pin, pinnable: last_article, profile: user)
      get "/#{user.username}"
      expect(response.body).to include "Pinned"
    end

    xit "does not render pins if they don't exist" do
      get "/#{user.username}"
      expect(response.body).not_to include "Pinned"
    end

    xit "renders profile page of user after changed username" do
      old_username = user.username
      user.update(username: "new_username_yo_#{rand(10_000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    xit "renders profile page of user after two changed usernames" do
      old_username = user.username
      user.update(username: "new_hotness_#{rand(10_000)}")
      user.update(username: "new_new_username_#{rand(10_000)}")
      get "/#{old_username}"
      expect(response).to redirect_to("/#{user.username}")
    end

    xit "raises not found for banished users" do
      banishable_user = create(:user)
      Moderator::BanishUser.call(admin: user, user: banishable_user)
      expect { get "/#{banishable_user.reload.old_username}" }.to raise_error(ActiveRecord::RecordNotFound)
      expect { get "/#{banishable_user.reload.username}" }.to raise_error(ActiveRecord::RecordNotFound)
    end

    xit "renders noindex meta if banned" do
      user.add_role(:banned)
      get "/#{user.username}"
      expect(response.body).to include("<meta name=\"googlebot\" content=\"noindex\">")
    end

    xit "does not render noindex meta if not banned" do
      get "/#{user.username}"
      expect(response.body).not_to include("<meta name=\"googlebot\" content=\"noindex\">")
    end

    xit "renders rss feed link if any stories" do
      create(:article, user_id: user.id)

      get "/#{user.username}"
      expect(response.body).to include("/feed/#{user.username}")
    end

    xit "does not render feed link if no stories" do
      get "/#{user.username}"
      expect(response.body).not_to include("/feed/#{user.username}")
    end

    context "when organization" do
      xit "renders organization page if org" do
        get organization.path
        expect(response.body).to include CGI.escapeHTML(organization.name)
      end

      xit "renders organization users on sidebar" do
        create(:organization_membership, user_id: user.id, organization_id: organization.id)
        get organization.path
        expect(response.body).to include user.profile_image_url
      end

      xit "renders no sponsors if not sponsor" do
        get organization.path
        expect(response.body).not_to include "Gold Community Sponsor"
      end

      xit "renders sponsor if it is sponsored" do
        create(:sponsorship, level: :gold, status: :live, organization: organization)
        get organization.path
        expect(response.body).to include "Gold Community Sponsor"
      end

      xit "renders organization name properly encoded" do
        organization.update(name: "Org & < ' \" 1")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.name))
      end

      xit "renders organization email properly encoded" do
        organization.update(email: "t&st&mail@dev.to")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.email))
      end

      xit "renders organization summary properly encoded" do
        organization.update(summary: "Org & < ' \" &quot; 1")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.summary))
      end

      xit "renders organization location properly encoded" do
        organization.update(location: "123, ave dev & < ' \" &quot; to")
        get organization.path
        expect(response.body).to include(ActionController::Base.helpers.sanitize(organization.location))
      end

      xit "renders rss feed link if any stories" do
        create(:article, organization_id: organization.id)
        get organization.path
        expect(response.body).to include("/feed/#{organization.slug}")
      end

      xit "does not render feed link if no stories" do
        get organization.path
        expect(response.body).not_to include("/feed/#{organization.slug}")
      end
    end

    context "when displaying a GitHub repository on the profile" do
      let(:github_user) { create(:user, :with_identity, identities: %i[github]) }
      let(:params) do
        {
          description: "A book bot :robot:",
          featured: true,
          github_id_code: build(:github_repo).github_id_code,
          name: Faker::Book.title,
          stargazers_count: 1,
          url: Faker::Internet.url
        }
      end

      before do
        omniauth_mock_github_payload
      end

      xit "renders emoji in description of featured repository" do
        GithubRepo.upsert(github_user, params)

        get "/#{github_user.username}"
        expect(response.body).to include("A book bot 🤖")
      end

      xit "does not show a non featured repository" do
        GithubRepo.upsert(github_user, params.merge(featured: false))

        get "/#{github_user.username}"
        expect(response.body).not_to include("A book bot 🤖")
      end

      xit "does not render anything if the user has not authenticated through GitHub" do
        get "/#{github_user.username}"
        expect(response.body).not_to include("github-repos-container")
      end
    end
  end

  describe "redirect to moderation" do
    xit "redirects to admin" do
      user = create(:user)
      get "/#{user.username}/admin"
      expect(response.body).to redirect_to "/admin/users/#{user.id}/edit"
    end

    xit "redirects to moderate" do
      user = create(:user)
      get "/#{user.username}/moderate"
      expect(response.body).to redirect_to "/internal/users/#{user.id}"
    end
  end
end
