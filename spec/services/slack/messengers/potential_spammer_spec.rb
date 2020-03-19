require "rails_helper"

RSpec.describe Slack::Messengers::PotentialSpammer, type: :service do
  let_it_be_readonly(:user) { create(:user) }

  let(:default_params) do
    {
      user: user
    }
  end

  it "contains the correct info", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: SlackBotPingWorker) do
      described_class.call(default_params)
    end

    job = sidekiq_enqueued_jobs(worker: SlackBotPingWorker).last
    message = job["args"].first["message"]

    url = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}/#{user.username}"
    expect(message).to include(url)
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: SlackBotPingWorker) do
      described_class.call(default_params)
    end

    job = sidekiq_enqueued_jobs(worker: SlackBotPingWorker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq("potential-spam")
    expect(job_args["username"]).to eq("spam_account_checker_bot")
    expect(job_args["icon_emoji"]).to eq(":exclamation:")
  end
end
