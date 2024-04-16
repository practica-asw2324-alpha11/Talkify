class AddSubscriptionsAMagazines < ActiveRecord::Migration[7.0]
  def change
    create_join_table :magazines, :admins do |t|
      # t.index :magazine_id
      # t.index :admin_id
    end
  end
end
