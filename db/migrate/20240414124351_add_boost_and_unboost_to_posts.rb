class AddBoostAndUnboostToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :boost, :integer
    add_column :posts, :unboost, :integer
  end
end
