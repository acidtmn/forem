module Mentions
  class CreateAll
    def initialize(notifiable)
      @notifiable = notifiable
    end

    def self.call(...)
      new(...).call
    end

    def call
      # Creates mentions + associated notifications for Articles and Comments.
      mentioned_users = users_mentioned_in_text_excluding_author

      delete_mentions_removed_from_notifiable_text(mentioned_users)
      create_mentions_for(mentioned_users)
    end

    private

    def users_mentioned_in_text_excluding_author
      mentioned_usernames = extract_usernames_from_mentions_in_text

      collect_existing_users(mentioned_usernames)
        .yield_self do |existing_mentioned_users|
          reject_notifiable_author(existing_mentioned_users)
        end
    end

    def collect_existing_users(usernames)
      User.registered.where(username: usernames)
    end

    def create_mentions_for(users)
      users.each { |user| create_mention_for(user) }
    end

    def extract_usernames_from_mentions_in_text
      # The "mentioned-user" css is added by Html::Parser#user_link_if_exists
      doc = Nokogiri::HTML(notifiable.processed_html)

      # Remove any mentions that are embedded within a comment liquid tag
      non_liquid_tag_mentions = doc.css(".mentioned-user").reject do |tag|
        tag.ancestors(".liquid-comment").any?
      end

      non_liquid_tag_mentions.map { |link| link.text.delete("@").downcase }
    end

    def reject_notifiable_author(users)
      users.reject { |user| authored_by?(user, @notifiable) }
    end

    def authored_by?(user, notifiable)
      user.id == notifiable.user_id
    end

    def delete_mentions_removed_from_notifiable_text(users)
      mentions = @notifiable.mentions.where.not(user_id: users).destroy_all
      Notification.remove_all(notifiable_ids: mentions.map(&:id), notifiable_type: "Mention") if mentions.present?
    end

    def user_has_comment_notifications?(user)
      user.notifications.exists?(notifiable_id: @notifiable.id, notifiable_type: "Comment")
    end

    def create_mention_for(user)
      return if user_has_comment_notifications?(user)

      # The mentionable_type is the model that created the mention, the user is the user to be mentioned.
      mention = Mention.create(user_id: user.id, mentionable_id: @notifiable.id,
                               mentionable_type: @notifiable.class.name)

      # If notifiable is an Article, we need to create the mention and associated notification immediately so
      # that we have it in the database before kicking off any workers that send other Article-related notifications.
      # However, if notifiable is a Comment, we can create the mention notification inline.
      Notification.send_mention_notification_without_delay(mention) if notifiable.is_a?(Article)
      Notification.send_mention_notification(mention) if notifiable.is_a?(Comment)

      mention
    end

    attr_reader :notifiable
  end
end
