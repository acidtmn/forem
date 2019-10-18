module Api
  module V0
    class FollowersController < ApiController
      before_action :authenticate_with_api_key_or_current_user!, only: [:index]
      before_action -> { limit_per_page(default: 80, max: 1000) }, only: [:index]

      def index
        query = if params[:which] == "organization_user_followers"
                  { followable_id: current_user.organization_id, followable_type: "Organization" }
                else
                  { followable_id: current_user.id, followable_type: "User" }
                end

        @follows = Follow.
          where(query).
          includes(:follower).
          order("created_at DESC").
          page(params[:page]).
          per(@follows_limit)
      end

      private

      def limit_per_page(default:, max:)
        per_page = (params[:per_page] || default).to_i
        @follows_limit = [per_page, max].min
      end
    end
  end
end
