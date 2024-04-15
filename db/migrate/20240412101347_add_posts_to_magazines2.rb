class AddPostsToMagazines2 < ActiveRecord::Migration[7.0]
  def change
    add_reference :posts, :magazine, null: false, foreign_key: true
  end
end
