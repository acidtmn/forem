require "rails_helper"

RSpec.describe "Creating an article with the editor", type: :system do
  let(:user) { create(:user) }
  let!(:article_body) { file_fixture("article_published.txt").read }

  before do
    sign_in user
  end

  it "creates a new article", js: true, retry: 3 do
    visit new_path
    fill_in "article_body_markdown", with: article_body
    click_button "SAVE CHANGES"
    expect(page).to have_selector("header h1", text: "Sample Article")
  end
end
