module Stories
  class FeedsController < ApplicationController
    respond_to :json

    def show
      @page = (params[:page] || 1).to_i
      @stories = assign_feed_stories

      add_pinned_article
    end

    private

    def add_pinned_article
      return if params[:timeframe].present?

      pinned_article = PinnedArticle.get
      return if pinned_article.nil? || @stories.detect { |story| story.id == pinned_article.id }

      @stories.prepend(pinned_article.decorate)
    end

    def assign_feed_stories
      # [Ridhwana]: the if statement is a bit verbose at the moment but we're hoping to refactor out more of the feeds
      #  to use it and thereafter at some point maybe we can remove the if statement and just call the method directly.
      stories = if params[:timeframe] == Timeframe::LATEST_TIMEFRAME ||
          params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
                  # [Ridhwana]: I've not called passed params[:tag] here because I dont think we need it on the home
                  # feed but we should double check.
                  Articles::Feeds::FilterQuery.call(timeframe: params[:timeframe], page: @page, user: current_user)
                elsif user_signed_in?
                  signed_in_base_feed
                else
                  # [Ridhwana]: I think this never gets called because signed out should be handled by the server,
                  # but I'd like us to confirm.
                  signed_out_base_feed
                end

      ArticleDecorator.decorate_collection(stories)
    end

    def signed_in_base_feed
      # [Ridhwana]: We need to update the Basic feed and the VariantQuery to include the following tags.
      # we may want to try to use the Articles::Feeds::FilterQuery for Basic if we can but I suspect
      # it may be challenging for the variant query.
      feed = if Settings::UserExperience.feed_strategy == "basic"
               Articles::Feeds::Basic.new(user: current_user, page: @page, tag: params[:tag])
             else
               Articles::Feeds.feed_for(
                 user: current_user,
                 controller: self,
                 page: @page,
                 tag: params[:tag],
                 number_of_articles: 35,
               )
             end
      Datadog::Tracing.trace("feed.query",
                             span_type: "db",
                             resource: "#{self.class}.#{__method__}",
                             tags: { feed_class: feed.class.to_s.dasherize }) do
        # Hey, why the to_a you say?  Because the
        # LargeForemExperimental has already done this.  But the
        # weighted strategy has not.  I also don't want to alter the
        # weighted query implementation as it returns a lovely
        # ActiveRecord::Relation.  So this is a compromise.
        feed.more_comments_minimal_weight_randomized.to_a
      end
    end

    def signed_out_base_feed
      feed = if Settings::UserExperience.feed_strategy == "basic"
               Articles::Feeds::Basic.new(user: nil, page: @page, tag: params[:tag])
             else
               Articles::Feeds.feed_for(
                 user: current_user,
                 controller: self,
                 page: @page,
                 tag: params[:tag],
                 number_of_articles: 25,
               )
             end
      Datadog::Tracing.trace("feed.query",
                             span_type: "db",
                             resource: "#{self.class}.#{__method__}",
                             tags: { feed_class: feed.class.to_s.dasherize }) do
        # Hey, why the to_a you say?  Because the
        # LargeForemExperimental has already done this.  But the
        # weighted strategy has not.  I also don't want to alter the
        # weighted query implementation as it returns a lovely
        # ActiveRecord::Relation.  So this is a compromise.
        feed.default_home_feed(user_signed_in: false).to_a
      end
    end
  end
end
