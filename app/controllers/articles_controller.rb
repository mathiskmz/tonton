class ArticlesController < ApplicationController
  require "open-uri"
  require "nokogiri"
  require "rss"

  def index
    @articles = Article.all
  end
  def new
    @article = Article.new
  end

  def create
    rss_feed_url = params[:article][:rss_feed_link]
    rss = URI.parse(rss_feed_url).read
    feed = RSS::Parser.parse(rss)
    feed.items.each do |item|
      unless Article.find_by(rss_title: item.title) 
        article = Article.new(
          rss_feed_link: rss_feed_url,
          rss_title: item.title,
          rss_desc: item.description,
          rss_article_link: item.link,
          content_scrapped: get_content_france_info(item.link).text,
          resume_from_llm: resume_article(get_content_france_info(item.link).text)
        )
        article.save!
      end
    end
  end

  def show
    @article = Article.find(params[:id])
  end


  private

  def get_content_france_info(article_link)
    html = URI.parse(article_link).read
    doc = Nokogiri::HTML.parse(html)

    doc.search(".c-body").each do |element|
      array = element.text.split
      full_text = array.map do |mot|
        " #{mot}"
      end
      full_text.join
    end
  end

  def resume_article(content)
    system_prompt = "Tu es un journaliste et tu vas recevoir un texte. 
    Il faudra que tu résumes ce texte en 100 mots max."
    # il faudra penser à passer sur une clé LLM (et reconfiguration) OpenAI ou Anthropic directement pour éviter certains
    # filtres restrictifs avec Azure via GitHub --> certains articles sont actuellement non résumé par le LLM et donc
    # absence de resume_from_llm (nil)
    RubyLLM.chat.with_instructions(system_prompt).ask(content).content
  rescue StandardError
    nil
  end
end
