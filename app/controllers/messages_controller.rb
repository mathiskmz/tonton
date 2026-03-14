class MessagesController < ApplicationController

  BASE_PROMPT = "Tu prends le rôle d'un oncle cultivé autour d'un diner familial qui répond chaleureusement 
  et explicitement avec une vraie envie de transmettre de la connaissance."
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"
    if @message.save
      llm_set = RubyLLM.chat
      llm_set_base = llm_set.with_instructions(BASE_PROMPT)
      llm_prompt = llm_set_base.ask(@message.content)
      llm_response = llm_prompt.content
      Message.create(role: "assistant", content: llm_response, chat_id: @chat.id)
      
      redirect_to chat_path(@message.chat)
    else
      @chat = @message.chat
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :role, :chat_id)
  end
end
