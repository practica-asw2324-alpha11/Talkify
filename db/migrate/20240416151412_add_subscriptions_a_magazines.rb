class AddSubscriptionsAMagazines < ActiveRecord::Migration[7.0]
  def change
    create_join_table :magazines, :users do |t|
      # t.index :magazine_id
      # t.index :user_id
    end
  end
end
