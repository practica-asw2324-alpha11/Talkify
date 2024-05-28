class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :vote_type, inclusion: { in: ['upvote', 'downvote'] }
end
