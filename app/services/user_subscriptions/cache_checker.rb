module UserSubscriptions
  class CacheChecker
    attr_accessor :user, :source_type, :source_id

    def initialize(user, source_type, source_id)
      @user = user
      @source_type = source_type
      @source_id = source_id
    end

    def cached_subscription_check
      return false unless user

      cache_key = "user-#{user.id}-#{user.updated_at.rfc3339}-#{user.subscribed_to_user_subscriptions_count}/is_subscribed_#{source_type}_#{source_id}"
      Rails.cache.fetch(cache_key, expires_in: 24.hours) do
        UserSubscription.where(
          subscriber_id: user.id,
          user_subscription_sourceable_type: source_type,
          user_subscription_sourceable_id: source_id,
        ).any?
      end
    end
  end
end
