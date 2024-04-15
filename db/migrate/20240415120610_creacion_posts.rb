class CreacionPosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :url
      t.string :body
      t.boolean :link

      t.timestamps
    end
    add_reference :posts, :admin, null:false, foreign_key: true
  end
end