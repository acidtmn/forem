class EmailDigestArticleCollector
  include FieldTest::Helpers
  include Instrumentation

  ARTICLES_TO_SEND = "EmailDigestArticleCollector#articles_to_send".freeze
  RESULTS_COUNT = 7 # Winner of digest_count_03_18 field test
  CLICK_LOOKBACK = 30

  def initialize(user)
    @user = user
  end

  def articles_to_send
    # rubocop:disable Metrics/BlockLength
    order = Arel.sql("((score * (feed_success_score + 0.1)) - clickbait_score) DESC")
    instrument ARTICLES_TO_SEND, tags: { user_id: @user.id } do
      return [] unless should_receive_email?

      articles = if user_has_followings?
                   experience_level_rating = @user.setting.experience_level || 5
                   experience_level_rating_min = experience_level_rating - 4
                   experience_level_rating_max = experience_level_rating + 4

                   @user.followed_articles
                     .select(:title, :description, :path)
                     .published
                     .where("published_at > ?", cutoff_date)
                     .where(email_digest_eligible: true)
                     .not_authored_by(@user.id)
                     .where("score > ?", 8)
                     .where("experience_level_rating > ? AND experience_level_rating < ?",
                            experience_level_rating_min, experience_level_rating_max)
                     .order(order)
                     .limit(RESULTS_COUNT)
                 else
                   Article.select(:title, :description, :path)
                     .published
                     .where("published_at > ?", cutoff_date)
                     .featured
                     .where(email_digest_eligible: true)
                     .not_authored_by(@user.id)
                     .where("score > ?", 15)
                     .order(order)
                     .limit(RESULTS_COUNT)
                 end

      articles.length < 3 ? [] : articles
    end
    # rubocop:enable Metrics/BlockLength
  end

  def should_receive_email?
    return true unless last_email_sent
  
    lookback = Settings::General.periodic_email_digest.days.ago

    email_sent_before_lookback = last_email_sent.before?(lookback)
    return true if email_sent_before_lookback # No need to do extra recent_tracked_click? if this is true

    email_sent_recently_with_click = !last_email_sent.before?(lookback) && recent_tracked_click?
    email_sent_before_lookback || email_sent_recently_with_click
  end

  def should_receive_email?
    return true unless last_email_sent # Send if no emails have ever been sent
  
    lookback = Settings::General.periodic_email_digest.days.ago
  
    email_sent_before_lookback = last_email_sent < lookback
  
    email_sent_during_lookback_without_click = last_email_sent >= lookback && !recent_tracked_click?
  
    email_sent_before_lookback && !email_sent_during_lookback_without_click
  end

  private

  def recent_tracked_click?
    @user.email_messages
      .where(mailer: "DigestMailer#digest_email")
      .where("sent_at > ?", CLICK_LOOKBACK.days.ago)
      .where.not(clicked_at: nil).any?
  end

  def last_email_sent
    @last_email_sent ||=
      @user.email_messages
        .where(mailer: "DigestMailer#digest_email")
        .maximum(:sent_at)
  end

  def cutoff_date
    a_few_days_ago = 7.days.ago.utc
    return a_few_days_ago unless last_email_sent

    [a_few_days_ago, last_email_sent].max
  end

  def user_has_followings?
    @user.following_users_count.positive? ||
      @user.cached_followed_tag_names.any? ||
      @user.cached_antifollowed_tag_names.any?
  end
end
