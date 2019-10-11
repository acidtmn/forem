# frozen_string_literal: true

require "rails_helper"

describe ChatChannels::IndexJob, type: :job do
  include_examples "#enqueues_job", "chat_channels_index", chat_channel_id: 1

  describe "#perform" do
    let(:chat_channel) { build :chat_channel }
    let(:chat_channel_id) { 1 }

    context "when chat_channel is found" do
      before do
        allow(ChatChannel).to receive(:find_by).with(id: chat_channel_id).and_return(chat_channel)
        allow(chat_channel).to receive(:index!)
      end

      it "calls index" do
        described_class.new.perform(chat_channel_id: chat_channel_id)
        expect(chat_channel).to have_received(:index!)
      end
    end

    context "when chat_channel is not found" do
      before do
        allow(ChatChannel).to receive(:find_by).with(id: chat_channel_id).and_return(nil)
        allow(chat_channel).to receive(:index!)
      end

      it "don't calls index" do
        described_class.new.perform(chat_channel_id: chat_channel_id)
        expect(chat_channel).not_to have_received(:index!)
      end
    end
  end
end
