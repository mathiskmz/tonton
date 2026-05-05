class AddUserRefToArticles < ActiveRecord::Migration[8.1]
  def change
    add_reference :articles, :user, null: true, foreign_key: true
  end
end
