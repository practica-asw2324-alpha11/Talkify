class CommentVote < ApplicationRecord
  belongs_to :admin
  belongs_to :comment

  validates :vote_type, inclusion: { in: ['upvote', 'downvote'] }
end
