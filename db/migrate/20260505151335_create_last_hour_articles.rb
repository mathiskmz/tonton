class CreateLastHourArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :last_hour_articles do |t|
      t.text :content_scrapped
      t.text :resume_from_llm
      t.text :rss_title
      t.text :rss_desc
      t.string :rss_article_link
      t.text :rss_feed_link
      t.column :embedding, :vector, limit: 1536
      t.string :image_link

      t.timestamps
    end
  end
end
