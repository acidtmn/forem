module Api
  module V0
    class ReactionsController < ApplicationController
      skip_before_action :verify_authenticity_token
      def create
        @user = valid_user
        unless @user
          render json: { message: "invalid_user" }, status: 422
          return
        end
        Rails.cache.delete "count_for_reactable-#{params[:reactable_type]}-#{params[:reactable_id]}"
        @reaction = Reaction.create(
          user_id: @user.id,
          reactable_id: params[:reactable_id],
          reactable_type: params[:reactable_type],
          category: params[:category] || "like",
        )
        Notification.send_reaction_notification(@reaction) if @reaction.reactable.user_id != current_user.id
        render json: { reaction: @reaction.to_json }
      end

      def onboarding
        verify_authenticity_token
        reactable_ids = JSON.parse(params[:articles]).map { |article| article["id"] }
        reactable_ids.each do |article_id|
          Reaction.delay.create(
            user_id: current_user.id,
            reactable_id: article_id,
            reactable_type: "Article",
            category: "readinglist",
          )
        end
      end

      private

      def valid_user
        user = User.find_by_secret(params[:key])
        user = nil if !user.has_role?(:super_admin)
        user
      end
    end
  end
end
