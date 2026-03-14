class Article < ApplicationRecord

  has_neighbors :embedding
  after_create :set_embedding

  private

  def set_embedding
    sleep(3)
    embedding = RubyLLM.embed("rss_title: #{self.rss_title}. rss_description: #{self.rss_desc}. resume_from_llm: #{self.resume_from_llm}")
    self.update(embedding: embedding.vectors)
  end
end
