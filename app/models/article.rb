class Article < ApplicationRecord
  attr_reader :rss_feed_link
  belongs_to :user
end
