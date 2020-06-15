require "rails_helper"

RSpec.describe "EmailSignups", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /email_signups - EmailSignups#create" do
    it "creates a UserSubscription" do
      article = create(:article, body_markdown: "---\ntitle: Email Signup#{rand(1000)}\npublished: true\n---\n\n{% email_signup 'CTA text' %}")
      valid_attributes = { source_type: article.class_name, source_id: article.id }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: valid_attributes }.to_json
      end.to change(UserSubscription, :count).by(1)

      user_subscription = UserSubscription.last
      expect(user_subscription.subscriber_id).to eq user.id
      expect(user_subscription.author_id).to eq article.user_id
      expect(user_subscription.user_subscription_sourceable_type).to eq article.class_name
      expect(user_subscription.user_subscription_sourceable_id).to eq article.id
    end

    it "returns an error for an invalid source_type" do
      invalid_source_type_attributes = { source_type: "NonExistentSourceType", source_id: "1" }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_type_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("invalid type")
    end

    it "returns an error for a source that can't be found" do
      invalid_source_attributes = { source_type: "Article", source_id: "99999999" }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("source not found")
    end

    it "returns an error for a source that doesn't have the EmailSignup liquid tag enabled" do
      article = create(:article)
      invalid_source_attributes = { source_type: article.class_name, source_id: article.id }
      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("email signups are not enabled for the requested source")
    end

    it "returns an error for an invalid UserSubscription" do
      article = create(:article, body_markdown: "---\ntitle: Email Signup#{rand(1000)}\npublished: true\n---\n\n{% email_signup 'CTA text' %}")

      # Create the UserSubscription directly so it results in a
      # duplicate/invalid record and returns an error. This mimics a user
      # trying to subscribe to the same user via the same source, twice.
      UserSubscription.create(subscriber: user, author: article.user, user_subscription_sourceable: article)

      invalid_source_attributes = { source_type: article.class_name, source_id: article.id }

      expect do
        post email_signups_path,
             headers: { "Content-Type" => "application/json" },
             params: { email_signup: invalid_source_attributes }.to_json
      end.to change(UserSubscription, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("Subscriber has already been taken")
    end
  end
end
