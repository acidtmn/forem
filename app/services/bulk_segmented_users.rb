class BulkSegmentedUsers
  def self.upsert(audience_segment, user_ids:)
    return unless audience_segment.manual? && audience_segment.persisted?

    now = Time.current
    valid_user_ids = User.where(id: user_ids).ids

    segmented_users = valid_user_ids.map do |user_id|
      {
        audience_segment_id: audience_segment.id,
        user_id: user_id,
        created_at: now,
        updated_at: now
      }
    end

    upserted_user_ids = SegmentedUser.upsert_all(
      segmented_users,
      unique_by: :index_segmented_users_on_audience_segment_and_user,
      update_only: [:updated_at],
      record_timestamps: false,
      returning: ["user_id"],
    ).rows.flatten

    {
      succeeded: upserted_user_ids,
      failed: user_ids - upserted_user_ids
    }
  end

  def self.delete(audience_segment, user_ids:)
    return unless audience_segment.manual? && audience_segment.persisted?

    segmented_users = audience_segment.segmented_users.where(user_id: user_ids)
    valid_user_ids = segmented_users.pluck(:user_id)
    segmented_users.delete_all

    {
      succeeded: valid_user_ids,
      failed: user_ids - valid_user_ids
    }
  end
end
