class CreacionComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.text :body
      t.integer :upvote, default: 0
      t.integer :downvote, default: 0

      t.timestamps
    end

    add_reference :comments, :post, null: false, foreign_key: true
    add_reference :comments, :admin, null: false, foreign_key: true

  end
end