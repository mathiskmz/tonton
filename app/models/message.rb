class Message < ApplicationRecord
  belongs_to :chat
  validates :content, :role, :chat_id, presence: true
end
