class ChatsController < ApplicationController
  def index
    @chats = Chat.all
  end

  def new
    @chat = Chat.new
  end

  def create
    new_chat = Chat.new(params[])
  end

  private

  def 
  params.require(:chat).permit(:title, :user_id)
end
