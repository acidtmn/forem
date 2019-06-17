require 'rails_helper'

RSpec.describe PollSkip, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:user) { create(:user) }
  let(:poll) { create(:poll, article_id: article.id) }

  it "is unique across poll and user" do
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    expect(PollSkip.all.size).to eq(1)
    second_poll = create(:poll, article_id: article.id)
    PollSkip.create(user_id: user.id, poll_id: second_poll.id)
    expect(PollSkip.all.size).to eq(2)
  end

  it "is unique across user and poll votes for the poll" do
    PollVote.create(user_id: user.id, poll_id: poll.id, poll_option_id: poll.poll_options.last.id)
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    expect(PollSkip.all.size).to eq(0)
    second_poll = create(:poll, article_id: article.id)
    PollSkip.create(user_id: user.id, poll_id: second_poll.id)
    expect(PollSkip.all.size).to eq(1)
  end

  it "is prevents a poll vote from being cast" do
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    PollSkip.create(user_id: user.id, poll_id: poll.id)
    PollVote.create(user_id: user.id, poll_id: poll.id, poll_option_id: poll.poll_options.last.id)
    expect(PollSkip.all.size).to eq(1)
    expect(PollVote.all.size).to eq(0)
  end
end
