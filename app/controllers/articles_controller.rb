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
    if params[:selected_links]
      articles_selected = params[:selected_links]
      list = articles_list_rss #relancer la génération des articles à sélectionner à partir du flux RSS // pour fiabiliser vaudrait mieux stocker l'array déjà généré dans la méthode dans une variable constante
      infos_articles_selected = articles_selected.map do |article_url|
        list.select do |article|
          article[:url] == article_url
        end
      end
      infos_articles_selected.each do |article|
        unless Article.find_by(rss_article_link: article.first[:url].split("#").first) #prévoir un message d'alerte si un article séléctionné était déja en DB
          article = Article.new(
            rss_title: article.first[:titre],
            rss_desc: article.first[:desc],
            rss_article_link: article.first[:url].split("#").first,
            image_link: article.first[:image],
            content_scrapped: get_content_france_info(article.first[:url].split("#").first).text,
            resume_from_llm: resume_article(get_content_france_info(article.first[:url].split("#").first).text)
          )
          article.save!
        end
      end
    else
      rss_feed_url = params[:article][:rss_feed_link]
      rss = URI.parse(rss_feed_url).read
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        unless Article.find_by(rss_title: item.title) 
          article = Article.new(
            rss_feed_link: rss_feed_url,
            rss_title: item.title,
            rss_desc: item.description,
            rss_article_link: item.link.split("#").first,
            content_scrapped: get_content_france_info(item.link.split("#").first).text,
            resume_from_llm: resume_article(get_content_france_info(item.link.split("#").first).text)
          )
          article.save!
        end
      end
    end
    redirect_to articles_path
  end

  def show
    @article = Article.find(params[:id])
  end

  def articles_list_rss
    rss = URI.parse("https://www.franceinfo.fr/titres.rss").read
    feed = RSS::Parser.parse(rss)
    @articles_recents = []
    articles_loop = feed.items.each do |article|
      @articles_recents.push({ titre: article.title, desc: article.description, url: article.link, image: article.enclosure.url })
    end
    return @articles_recents
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
