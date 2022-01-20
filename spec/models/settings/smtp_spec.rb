require "rails_helper"

RSpec.describe Settings::SMTP do
  after do
    described_class.clear_cache
  end

  describe "::settings" do
    it "use default sendgrid config if SENDGRID_API_KEY is available" do
      key = "something"
      domain = "test.com"
      allow(ApplicationConfig).to receive(:[]).with("SENDGRID_API_KEY").and_return(key)
      ENV["SENDGRID_API_KEY"] = "something"
      allow(Settings::General).to receive(:app_domain).and_return(domain)

      expect(described_class.settings).to eq({
                                               address: "smtp.sendgrid.net",
                                               port: 587,
                                               authentication: :plain,
                                               user_name: "apikey",
                                               password: key,
                                               domain: domain
                                             })
      ENV["SENDGRID_API_KEY"] = nil
    end

    # rubocop:disable RSpec/ExampleLength
    it "uses Settings::SMTP config if SENDGRID_API_KEY is not available" do
      from_email_address = "hello@forem.com"
      reply_to_email_address = "reply@forem.com"
      allow(described_class).to receive(:from_email_address).and_return(from_email_address)
      allow(described_class).to receive(:reply_to_email_address).and_return(reply_to_email_address)

      described_class.address = "smtp.google.com"
      described_class.port = 25
      described_class.authentication = "plain"
      described_class.user_name = "username"
      described_class.password = "password"
      described_class.domain = "forem.local"

      expect(described_class.settings).to eq({
                                               address: "smtp.google.com",
                                               port: 25,
                                               authentication: "plain",
                                               user_name: "username",
                                               password: "password",
                                               domain: "forem.local",
                                               reply_to_email_address: reply_to_email_address,
                                               from_email_address: from_email_address
                                             })
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
