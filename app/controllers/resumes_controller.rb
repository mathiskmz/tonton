class ResumesController < ApplicationController
  
  def show
    @synthesis = news_resume(Article.all.last(10))
  end

  private

  #news = array d'instances des 10 derniers articles
  def news_resume(news)
    system_prompt = "Tu es un oncle cultivé qui explique l'actualité à un membre de sa famille. tu séléctionnes un seul 
    et unique sujet particulièrement redondant dans l'actualité.
    Ton discours est structuré en paragraphes avec des sauts de lignes : contexte et rappels, présentation des faits, 
    divergences ou consensus sur le sujet, conclusion avec les implications à venir, et une phrase de conclusion. 
    250 mots maximum. Quelques emojis."

    prompt = news.map do |article|
      "\n\nTitre: #{article.rss_title} - Description éditoriale: #{article.rss_desc} - Resumé: #{article.resume_from_llm}"
    end.join

    RubyLLM.chat.with_instructions(system_prompt).ask(
      "voici l'actualité à synthétiser autour du sujet le plus central : #{prompt}").content
  end
end
