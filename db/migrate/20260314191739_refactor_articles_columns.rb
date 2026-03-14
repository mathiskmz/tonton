class RefactorArticlesColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :rss_feed_link, :text
    rename_column :articles, :article_link, :rss_article_link
    rename_column :articles, :content, :content_scrapped
    rename_column :articles, :resume, :resume_from_llm
    remove_column :articles, :title, :string
  end
end
