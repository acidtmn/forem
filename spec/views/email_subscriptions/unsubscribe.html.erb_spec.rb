require "rails_helper"

RSpec.describe "email_subscriptions/unsubscribe.html.erb", type: :view do
  it "works" do
    assign(:email_type, "#{SiteConfig.community_name} digest emails")
    render
    expect(rendered).to include("You have been unsubscribed from DEV(local) digest emails. 😔")
  end
end
