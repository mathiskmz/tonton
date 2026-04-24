class AddColumnImageLinkToArticle < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :image_link, :string
  end
end
