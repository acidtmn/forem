require "rails_helper"

RSpec.describe "layouts/_signup_modal.html.erb", type: :view do
  let(:tagline_text) { "the best community" }

  it "renders the tagline if it is set" do
    allow(SiteConfig).to receive(:tagline).and_return(tagline_text)
    render
    expect(rendered).to have_text(SiteConfig.tagline)
  end

  it "does not render the tagline if it is not set" do
    allow(SiteConfig).to receive(:tagline).and_return(nil)
    render
    expect(rendered).to have_no_text(tagline_text)
  end
end
