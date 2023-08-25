class FeedEvent < ApplicationRecord
  # These are "optional" mostly so that we can perform validated bulk inserts
  # without triggering article/user validation.
  # Since there are database-level constraints, it's fine to skip the automatic
  # Rails-side association validation (which causes an N+1 query).
  belongs_to :article, optional: true
  belongs_to :user, optional: true

  enum category: {
    impression: 0,
    click: 1
  }

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_SEARCH = "search".freeze
  CONTEXT_TYPE_TAG = "tag".freeze
  VALID_CONTEXT_TYPES = [
    CONTEXT_TYPE_HOME,
    CONTEXT_TYPE_SEARCH,
    CONTEXT_TYPE_TAG,
  ].freeze

  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }, presence: true
  # Since we have disabled association validation, this is handy to filter basic bad data
  validates :article_id, presence: true, numericality: { only_integer: true }
  validates :user_id, numericality: { only_integer: true }, allow_nil: true
end