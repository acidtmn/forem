require "rails_helper"

RSpec.describe "User uses response templates settings", type: :system do
  let!(:user) { create(:user) }
  let(:response_template) { create(:response_template, user: user) }

  context "when user is signed in" do
    before do
      sign_in user
      response_template
    end

    context "when user has a response template already" do
      it "can go to the edit page of the response template", js: true do
        visit "/settings/response-templates"
        click_link "Edit"

        expect(page).to have_current_path "/settings/response-templates/#{response_template.id}", ignore_query: true
      end

      it "shows the proper message when deleting a reponse template", js: true do
        wait_for_assertion { ResponseTemplate.find_by(user: user.id) }
        visit "/settings/response-templates"
        accept_confirm { ensure_modal_opens { click_button("Remove", wait: 5) } }

        expect(page).to have_text "was deleted."
      end
    end
  end
end
