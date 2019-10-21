require "rails_helper"

RSpec.describe "Infinite scroll on dashboard", type: :system, js: true do
  let(:default_per_page) { 5 }
  let(:total_records) { default_per_page * 2 }
  let(:user) { create(:user) }
  let!(:users) { create_list(:user, total_records) }
  let!(:tags) { create_list(:tag, total_records) }
  let!(:organizations) { create_list(:organization, total_records) }
  let!(:podcasts) { create_list(:podcast, total_records) }

  before do
    sign_in user
  end

  context "when /dashboard/user_followers is visited" do
    before do
      users.each do |u|
        create(:follow, follower: u, followable: user)
      end
    end

    it "scrolls through all users" do
      visit "/dashboard/user_followers?per_page=#{default_per_page}"
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_tags is visited" do
    before do
      tags.each do |tag|
        create(:follow, follower: user, followable: tag)
      end
    end

    it "scrolls through all tags" do
      visit dashboard_following_tags_path(per_page: default_per_page)
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_users is visited" do
    before do
      users.each do |u|
        create(:follow, follower: user, followable: u)
      end
    end

    it "scrolls through all users" do
      visit dashboard_following_users_path(per_page: default_per_page)
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_organizations is visited" do
    before do
      organizations.each do |organization|
        create(:follow, follower: user, followable: organization)
      end
    end

    it "scrolls through all users" do
      visit dashboard_following_organizations_path(per_page: default_per_page)
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end

  context "when /dashboard/following_podcasts is visited" do
    before do
      podcasts.each do |podcast|
        create(:follow, follower: user, followable: podcast)
      end
    end

    it "scrolls through all users" do
      visit dashboard_following_podcasts_path(per_page: default_per_page)
      page.execute_script("window.scrollTo(0, 100000)")
      page.assert_selector('div[id^="follows"]', count: total_records)
    end
  end
end
