require "open-uri"
require "nokogiri"

html = URI.parse("https://www.franceinfo.fr/societe/drogue/un-avocat-ecroue-deux-rappeurs-interpelles-4-millions-d-euros-saisis-ce-qu-il-faut-retenir-de-la-conference-de-presse-sur-la-dz-mafia-du-procureur-de-marseille_7867655.html").read
doc = Nokogiri::HTML.parse(html)

doc.search(".c-body").each do |element|
  array = element.text.split
  full_text = array.map do |mot|
    " #{mot}"
  end
  full_text.join
end
