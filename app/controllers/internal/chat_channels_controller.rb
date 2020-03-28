class Internal::ChatChannelsController < Internal::ApplicationController
  layout "internal"

  def index
    @group_chat_channels = ChatChannel.where(channel_type: "invite_only").includes(:users).page(params[:page]).per(50)
  end

  def create
    ChatChannel.create_with_users(users_by_param, "invite_only", chat_channel_params[:channel_name], "mod")
    redirect_back(fallback_location: "/internal/chat_channels")
  end

  def update
    @chat_channel = ChatChannel.find(params[:id])
    @chat_channel.invite_users(users_by_param, "mod")
    redirect_back(fallback_location: "/internal/chat_channels")
  end

  private

  def users_by_param
    User.where(username: chat_channel_params[:usernames_string].downcase.delete(" ").split(","))
  end

  def chat_channel_params
    allowed_params = %i[usernames_string channel_name]
    params.require(:chat_channel).permit(allowed_params)
  end
end
