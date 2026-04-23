class ChatsController < ApplicationController
  def index
    @chats = Chat.all
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(chats_params)
    @chat.user = current_user
    if @chat.save
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_from_article
    article = Article.find(params[:format])
    @chat = Chat.new(title: article.rss_title)
    @chat.user = current_user
    if @chat.save
      llm_set = RubyLLM.chat
      llm_set_base = llm_set.with_instructions(base_prompt(@chat.messages))
      llm_prompt = llm_set_base.ask(article.content_scrapped)
      llm_response = llm_prompt.content
      Message.create(role: "assistant", content: llm_response, chat_id: @chat.id)
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages
    @message = Message.new
  end

  private

  def chats_params
    params.require(:chat).permit(:title, :user_id)
  end
end
