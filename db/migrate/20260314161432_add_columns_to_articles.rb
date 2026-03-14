class AddColumnsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :rss_title, :text
    add_column :articles, :rss_desc, :text
    add_column :articles, :article_link, :string
  end
end
