module Emails
  class DripEmailWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15

    def perform
      return unless FeatureFlag.enabled?('onboarding_drip_emails')

      last_drip_day = Email.where(type_of: 'onboarding_drip').maximum(:drip_day)
      return unless last_drip_day

      (1..last_drip_day).each do |drip_day|
        email_template = Email.find_by(type_of: 'onboarding_drip', drip_day: drip_day)
        next unless email_template

        start_time = ((drip_day * 24) + 1).hours.ago
        end_time = (drip_day * 24).hours.ago

        users = User.where(registered_at: start_time..end_time)

        users.each do |user|
          recent_email_sent = EmailMessage.where(user: user).where('sent_at >= ?', 12.hours.ago).exists?
          next if recent_email_sent

          CustomMailer.with(user: user, subject: email_template.subject, content: email_template.body)
                      .custom_email.deliver_now
        end
      end
    end
  end
end
