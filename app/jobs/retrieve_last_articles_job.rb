class RetrieveLastArticlesJob < ApplicationJob
  queue_as :default

  def perform
    # toutes les heures, vider et charger la table LastHourArticles avec les articles du feed RSS titres, france, monde
    # attention ici c'est la table entière, et donc commune a tous les utilisateurs qui est vidée
    LastHourArticle.delete_all

    # rss_titres = "https://www.franceinfo.fr/titres.rss"
    # rss_france = "https://www.franceinfo.fr/france.rss"
    # rss_monde = "https://www.franceinfo.fr/monde.rss"

    rss_to_load = ["https://www.franceinfo.fr/titres.rss", "https://www.franceinfo.fr/france.rss", "https://www.franceinfo.fr/monde.rss"]

    rss_to_load.each do |link|
      rss = URI.parse(link).read
      feed = RSS::Parser.parse(rss)
      feed.items.each do |article|
        article_created = LastHourArticle.new(
          rss_feed_link: link,
          rss_title: article.title,
          rss_desc: article.description,
          rss_article_link: article.link.split("#").first,
          content_scrapped: get_content_france_info(article.link.split("#").first).text,
          resume_from_llm: resume_article(get_content_france_info(article.link.split("#").first).text)
        )
        article_created.save
      end
    end
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
