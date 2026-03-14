class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :content
      t.text :resume

      t.timestamps
    end
  end
end
