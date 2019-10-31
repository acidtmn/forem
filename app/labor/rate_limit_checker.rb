class RateLimitChecker
  attr_reader :user, :action

  def self.daily_account_follow_limit
    ENV["DAILY_ACCOUNT_FOLLOW_LIMIT"]&.to_i || 500
  end

  def initialize(user = nil)
    @user = user
  end

  class UploadRateLimitReached < StandardError; end
  class DailyFollowAccountLimitReached < StandardError; end

  def limit_by_action(action)
    result = case action
             when "comment_creation"
               user.comments.where("created_at > ?", 30.seconds.ago).size > 9
             when "published_article_creation"
               user.articles.published.where("created_at > ?", 30.seconds.ago).size > 9
             when "image_upload"
               Rails.cache.read("#{user.id}_image_upload").to_i > 9
             when "follow_account"
               user_today_follow_count > self.class.daily_account_follow_limit
             else
               false
             end
    if result
      @action = action
      ping_admins
    end
    result
  end

  def track_image_uploads
    count = Rails.cache.read("#{@user.id}_image_upload").to_i
    count += 1
    Rails.cache.write("#{@user.id}_image_upload", count, expires_in: 30.seconds)
  end

  def limit_by_email_recipient_address(address)
    # This is related to the recipient, not the "user" initiator, like in action.
    EmailMessage.where(to: address).
      where("sent_at > ?", 2.minutes.ago).size > 5
  end

  def ping_admins
    RateLimitCheckerJob.perform_later(user.id, action)
  end

  private

  def user_today_follow_count
    now = Time.zone.now
    day_start = now.beginning_of_day
    day_end = now.end_of_day

    user.follows.where(created_at: (day_start..day_end)).size
  end
end
