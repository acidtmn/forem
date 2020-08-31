require "rails_helper"

RSpec.describe GithubRepos::RepoSyncWorker, type: :worker do
  let(:worker) { subject }
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:repo) { create(:github_repo, user: user) }

  before { omniauth_mock_github_payload }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    let(:fake_github_client) do
      Class.new(Github::OauthClient) do
        def repository(name); end
      end
    end

    let(:stubbed_github_repo) do
      OpenStruct.new(repo.attributes.merge(id: repo.github_id_code, html_url: repo.url)) # rubocop:disable Performance/OpenStruct
    end
    let(:github_client) { instance_double(fake_github_client, repository: stubbed_github_repo) }

    before do
      allow(Github::OauthClient).to receive(:new).and_return(github_client)
    end

    it "updates all repositories" do
      old_updated_at = repo.updated_at

      Timecop.freeze(3.days.from_now) do
        worker.perform(repo.id)
        expect(old_updated_at).not_to eq(GithubRepo.find(repo.id).updated_at)
      end
    end

    it "destroys unfound repos" do
      repo_id = repo.id
      allow(github_client).to receive(:repository).and_raise(Github::Errors::NotFound)

      worker.perform(repo.id)
      expect(GithubRepo.find_by(id: repo_id)).to be_nil
    end

    it "destroys Unauthorized repos" do
      repo_id = repo.id
      allow(github_client).to receive(:repository).and_raise(Github::Errors::Unauthorized)

      worker.perform(repo.id)
      expect(GithubRepo.find_by(id: repo_id)).to be_nil
    end

    it "destroys suspended account repos" do
      repo_id = repo.id
      client_error = Github::Errors::ClientError.new(message: "GET https:// 403 - Sorry. Your account was suspended.")
      allow(github_client).to receive(:repository).and_raise(client_error)

      worker.perform(repo.id)
      expect(GithubRepo.find_by(id: repo_id)).to be_nil
    end

    it "destroys blocked access repos" do
      repo_id = repo.id
      client_error = Github::Errors::ClientError.new(message: "GET https:// 451 - Repository access blocked.")
      allow(github_client).to receive(:repository).and_raise(client_error)

      worker.perform(repo.id)
      expect(GithubRepo.find_by(id: repo_id)).to be_nil
    end
  end
end
