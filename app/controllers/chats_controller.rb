class ChatsController < ApplicationController
  require "open-uri"
  require "nokogiri"
  require "rss"

  def index
    @chats = Chat.all
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = Chat.new(chats_params)
    @chat.user = current_user
    if @chat.save
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_from_article
    article = Article.find(params[:format])
    @chat = Chat.new(title: article.rss_title)
    @chat.user = current_user
    if @chat.save
      llm_set = RubyLLM.chat
      llm_set_base = llm_set.with_instructions(base_prompt(@chat.messages))
      llm_prompt = llm_set_base.ask(article.content_scrapped)
      llm_response = llm_prompt.content
      Message.create(role: "assistant", content: llm_response, chat_id: @chat.id)
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_from_news_checkup
    #récupérer les articles du feed RSS https://www.franceinfo.fr/titres.rs et stocker dans un hash
    #redondance articles_controller => REFACTO
    @articles_recents = []
    rss = URI.parse("https://www.franceinfo.fr/titres.rss").read
    feed = RSS::Parser.parse(rss)
    feed.items.each do |item|
      article = Article.new(
        rss_feed_link: "https://www.franceinfo.fr/titres.rss",
        rss_title: item.title,
        rss_desc: item.description,
        rss_article_link: item.link.split("#").first,
        content_scrapped: get_content_france_info(item.link.split("#").first).text,
        resume_from_llm: resume_article(get_content_france_info(item.link.split("#").first).text)
      )
      @articles_recents.push(article)
    end
    #donner ce hash à un agent IA pour prioriser et extraire un sujet important et récurrent
    topic = main_topic(@articles_recents)
    #donner le hash à un autre agent IA pour séléctionner les articles relatifs au sujet
    relevant_articles = select_relevant_articles(topic, @articles_recents)

    #AMELIORATION : stocker en BD RAG les articles à la une des 10 derniers jours, permettant à un LLM d'avoir un meilleur contexte de l'actualité
    #AMELIORATION : possibilité pour l'agent IA d'accéder aux articles d'un feed spécifique si besoin selon le sujet principal (politique, etc)
    
    #donner le hash avec les articles séléctionnés à un LLM pour obtenir une synthèse explicative (contexte, faits, enjeux)
    tonton_first_message = first_message_sumup_articles(relevant_articles)
    
    chat = Chat.new(title: topic, user_id: current_user.id)
    chat.save
    message = Message.new(chat_id: chat.id, content: tonton_first_message, role: "assistant")
    if message.save
      redirect_to chat_path(chat)
    else
      render :home, status: :unprocessable_entity #bien prévoir un message d'erreur et un lancement du chat manuel avec un premier message de l'utilisateur
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages
    @message = Message.new
  end

  private

  def chats_params
    params.require(:chat).permit(:title, :user_id)
  end

  #redondance articles_controller => REFACTO
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

  #redondance articles_controller => REFACTO
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

  def main_topic(hash_of_articles)
    system_prompt = "Ton rôle est d'extraire en une phrase de 5 à 15 mots,
    le sujet principale au sein de ce hash constitué d'articles. Selon la récurrence, l'importance, etl'urgence des sujets.
    Fais preuve de discernement et de pertinence, comme si tu devais choisir l'actualité la plus pertinente pour ensuite l'expliquer à un ami.
    Extrait un sujet plutôt grand public, ayant un intérêt/impact pour le plus grand nombre de personne. "
    RubyLLM.chat.with_instructions(system_prompt).ask(hash_of_articles.to_json).content
  end

  def select_relevant_articles(topic, hash_of_articles)
    system_prompt = "Ton rôle est de séléctionner les articles correspondants à ce sujet : #{topic}.
    Renvoie la totalité des clés et valeurs associées aux articles que tu auras séléctionnés, afin de constituer ensuite un array de hash d'articles."
    RubyLLM.chat.with_instructions(system_prompt).ask(hash_of_articles.to_json).content
  end

  def first_message_sumup_articles(hash_of_selected_articles)
    system_prompt = "Tu prends le rôle d'un oncle cultivé autour d'un diner familial qui parle chaleureusement 
    et explicitement avec une vraie envie de transmettre de la connaissance. 
    Ton objectif est de synthétiser et expliquer le contenu des articles contenus dans le json que tu reçois.
    Tu réponds synthétiquement avec une mise en forme par paragraphe, et des sauts de lignes. 
    Structure ta réponse comme une note de synthèse avec une introduction d'environ 25 mots, un développement d'environ 50 mots, 
    et une conclusion d'environ 25 mots. Si pertinent, mets en avant les enjeux, les causes, les conséquences. 
    Mets des courts titres à chaque paragraphe qui synthétisent les idées du contenu, avec un emoji."
    RubyLLM.chat.with_instructions(system_prompt).ask(hash_of_selected_articles.to_json).content
  end
end
