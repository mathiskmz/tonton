class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages
  validates :title, presence: true
end
