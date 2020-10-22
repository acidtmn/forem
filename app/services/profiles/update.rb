module Profiles
  class Update
    include ImageUploads

    def self.call(user, updated_attributes = {})
      new(user, updated_attributes).call
    end

    attr_reader :error_message

    def initialize(user, updated_attributes)
      @user = user
      @profile = user.profile
      @updated_profile_attributes = updated_attributes[:profile] || {}
      @updated_user_attributes = updated_attributes[:user].to_h || {}
      @success = false
    end

    def call
      if update_successful?
        @user.touch(:profile_updated_at)
        follow_hiring_tag if SiteConfig.dev_to?
      else
        Honeycomb.add_field("error", @error_message)
        Honeycomb.add_field("errored", true)
      end
      self
    rescue ActiveRecord::RecordInvalid
      self
    end

    def success?
      @success
    end

    private

    def update_successful?
      return false unless verify_profile_image

      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless update_profile && update_user_attributes
      end
      true
    rescue ActiveRecord::Rollback
      false
    end

    def verify_profile_image
      image = @updated_user_attributes[:profile_image]
      return true unless image
      return true if valid_image_file?(image) && valid_filename?(image)

      false
    end

    def valid_image_file?(image)
      return true if file?(image)

      @error_message = IS_NOT_FILE_MESSAGE
      false
    end

    def valid_filename?(image)
      return true unless long_filename?(image)

      @error_message = FILENAME_TOO_LONG_MESSAGE
      false
    end

    def update_profile
      # Handle user specific custom profile fields
      if (custom_profile_attributes = @profile.custom_profile_attributes).any?
        custom_attributes = @updated_profile_attributes.extract!(*custom_profile_attributes)
        @updated_profile_attributes[:custom_attributes] = custom_attributes
      end

      # We don't update `data` directly. This uses the defined store_attributes
      # so we can make use of their typecasting.
      @profile.assign_attributes(@updated_profile_attributes)

      # Before saving, filter out obsolete profile fields
      @profile.data.slice!(*Profile.attributes)

      @profile.save
    end

    def update_user_attributes
      if (update = @user.update(@updated_user_attributes))
        @success = true
      else
        @error_message = @user.errors_as_sentence
      end
      update
    end

    def dev_to_follow_hiring_tag
      return unless @user.looking_for_work

      hiring_tag = Tag.find_by(name: "hiring")
      return unless hiring_tag && @user.following?(hiring_tag)

      Users::FollowWorker.perform_async(@user.id, hiring_tag.id, "Tag")
    end
  end
end
