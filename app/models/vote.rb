class Vote < ApplicationRecord
  belongs_to :admin
  belongs_to :post

  validates :vote_type, inclusion: { in: ['upvote', 'downvote'] }
end
