class PageViewRollup
  ATTRIBUTES_PRESERVED = %i[article_id counts_for_number_of_views created_at time_tracked_in_seconds user_id].freeze
  ATTRIBUTES_DESTROYED = %i[domain path referrer updated_at].freeze

  class ViewAggregator
    Compact = Struct.new(:views, :article_id, :user_id) do
      def to_h
        super.except(:views).merge({
                                     counts_for_number_of_views: views.sum(&:counts_for_number_of_views),
                                     time_tracked_in_seconds: views.sum(&:time_tracked_in_seconds)
                                   })
      end
    end

    def initialize
      @aggregator = Hash.new do |level1, article_id|
        level1[article_id] = Hash.new do |level2, user_id|
          level2[user_id] = []
        end
      end
    end

    def <<(view)
      @aggregator[event.article_id][event.user_id] << view
    end

    def each
      @aggregator.each_pair do |article_id, grouped_by_article_id|
        grouped_by_article_id.each_pair do |user_id, views|
          # next unless events.size > 1
          yield Compact.new(views, article_id, user_id)
        end
      end
    end

    private

    attr_reader :aggregator
  end

  def self.rollup(date, relation: PageView)
    new(relation: relation).rollup(date)
  end

  def initialize(relation:)
    @aggregator = EventAggregator.new
    @relation = relation
  end

  attr_reader :aggregator, :relation

  def rollup(date)
    created = []

    (0..23).each do |hour|
      start_hour = date.change(hour: hour)
      end_hour = date.change(hour: hour + 1)
      rows = relation.where(created_at: start_hour..end_hour)
      aggregate_into_groups(rows).each do |compacted_events|
        created << compact_records(start_hour, compacted_events)
      end
    end

    created
  end

  private

  def aggregate_into_groups(rows)
    rows.in_batches.each_record do |event|
      aggregator << event
    end

    aggregator
  end

  def compact_records(date, compacted)
    result = nil

    relation.transaction do
      result = relation.create!(compacted.to_h) do |event|
        event.created_at = date
      end

      relation.where(id: compacted.events).delete_all
    end

    result
  end
end
