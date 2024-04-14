class AdjustUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :description, :text
    add_column :users, :avatar, :string
    add_column :users, :background_image, :string
  end
end
