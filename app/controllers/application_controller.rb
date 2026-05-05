class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def base_prompt(messages_for_history)
    "Tu prends le rôle d'un oncle cultivé autour d'un diner familial qui répond chaleureusement 
    et explicitement avec une vraie envie de transmettre de la connaissance. Tu réponds synthétiquement avec une mise en forme par paragraphe, 
    et des sauts de lignes. Structure ta réponse comme une note de synthèse avec une introduction d'environ 25 mots, un développement d'environ 50 mots, 
    et une conclusion d'environ 25 mots. Si pertinent, mets en avant les enjeux, les causes, les conséquences. 
    Mets des courts titres à chaque paragraphe qui synthétisent les idées du contenu, avec un emoji.
    Voici l'historique de la conversation : #{build_history(messages_for_history)}"
  end

  def build_history(messages)
    messages.map { |m| "Role: #{m.role}, Message: #{m.content} -" }.join
  end
end
