class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password
      t.date :joined_date
      t.float :reputation_points
      t.integer :moderated

      t.timestamps
    end
  end
end
