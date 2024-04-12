class AddDefaultValueToUpvoteAndDownvote < ActiveRecord::Migration[7.0]
  def change
    change_column_default :comments, :upvote, 0
    change_column_default :comments, :downvote, 0
  end
end
