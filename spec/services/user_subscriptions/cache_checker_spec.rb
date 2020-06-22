require "rails_helper"

RSpec.describe UserSubscriptions::CacheChecker, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article) }

  it "checks if subscribed to a thing and returns true if they are" do
    create(:user_subscription,
           subscriber_id: user.id,
           subscriber_email: user.email,
           author_id: article.user_id,
           user_subscription_sourceable: article)

    expect(described_class.new(user, article.class_name, article.id).cached_subscription_check).to eq(true)
  end

  it "checks if subscribed to a thing and returns false if they are not" do
    expect(described_class.new(user, article.class_name, article.id).cached_subscription_check).to eq(false)
  end
end
