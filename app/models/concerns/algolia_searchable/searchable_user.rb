module AlgoliaSearchable
  module SearchableUser
    extend ActiveSupport::Concern

    included do
      algoliasearch(**DEFAULT_ALGOLIA_SETTINGS, unless: :bad_actor) do
        attribute :name, :username
        attribute :profile_image do
          profile_image_90
        end
      end
    end

    class_methods do
      def trigger_sidekiq_worker(record, delete)
        AlgoliaSearch::SearchIndexWorker.perform_async(record.class.name, record.id, delete)
      end
    end

    def bad_actor
      score.negative?
    end

    def bad_actor_changed?
      score_changed? && score_changed_between_negative_and_positive?
    end

    private

    def score_changed_between_negative_and_positive?
      score_was.negative? != score.negative?
    end
  end
end
