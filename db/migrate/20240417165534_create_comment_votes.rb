class CreateCommentVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :comment_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :comment, null: false, foreign_key: true
      t.string :vote_type

      t.timestamps
    end
  end
end
