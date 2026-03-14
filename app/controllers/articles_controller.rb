class ArticlesController < ApplicationController
  require "open-uri"
  require "nokogiri"
  require "rss"

  def new
    @article = Article.new
  end

  def create
    rss_feed_url = params[:article][:rss_feed]
    rss = URI.parse(rss_feed_url).read
    feed = RSS::Parser.parse(rss)
    feed.items.each do |item|
      article = Article.new(
        rss_title: item.title,
        rss_desc: item.description,
        article_link: item.link
      )
      raise
    end
  end
end
