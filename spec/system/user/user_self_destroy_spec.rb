require "rails_helper"

RSpec.describe "User destroys their profile", type: :system, js: true do
  let(:user) { create(:user) }
  let(:token) { SecureRandom.hex(10) }

  before do
    sign_in user
  end

  it "requests self-destroy" do
    visit "/settings/account"
    allow(Users::RequestDestroy).to receive(:call).and_call_original
    click_button "Delete Account"
    expect(Users::RequestDestroy).to have_received(:call).with(user)
  end

  it "displays a detailed error message when the user is not logged in" do
    sign_out user
    visit "/settings/account"
    expect(page).to have_text("You must be logged in to proceed with account deletion.")
  end

  it "displays a detailed error message when the user's token is invalid" do
    # rubocop:disable Layout/LineLength
    visit "/settings/account"
    allow(Users::RequestDestroy).to receive(:call).and_call_original
    click_button "Delete Account"
    allow(Rails.cache).to receive(:exist?).with("user-destroy-token-#{user.id}").and_return(false)
    expect do
      get user_confirm_destroy_path(token: token)
    end.to raise_error(UserDestroyToken::Errors::InvalidToken)
    expect(page).to have_text("Your token has expired, please request a new one. Tokens only last for 12 hours after account deletion is initiated.")
    # rubocop:enable Layout/LineLength
  end

  it "raises a 'Not Found' error if there is a token mismatch" do
    visit "/settings/account"
    click_button "Delete Account"
    allow(Rails.cache).to receive(:read).and_return(SecureRandom.hex(10))
    expect do
      get user_confirm_destroy_path(token: token)
    end.to raise_error(ActionController::RoutingError)
  end

  it "destroys an account" do
    allow(Rails.cache).to receive(:read).and_return(token)
    visit "/users/confirm_destroy/#{token}"
    fill_in "delete__account__username__field", with: user.username
    fill_in "delete__account__verification__field", with: "delete my account"
    sidekiq_assert_enqueued_with(job: Users::DeleteWorker) do
      click_button "DELETE ACCOUNT"
    end
  end
end
