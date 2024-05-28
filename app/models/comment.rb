class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent_comment, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_comment_id, dependent: :destroy
  has_many :comment_votes, dependent: :destroy

  after_initialize :set_default_values

  validates :body, presence: true, length: { minimum: 1 }


  def self.order_by(sort_by)
      case sort_by
      when "top"
        order(upvotes_count: :desc)
      when "newest"
        order(created_at: :desc)
      when "oldest"
        order(created_at: :asc)
      else
        order(created_at: :desc) # Ordenar por defecto por fecha de creación
      end
  end

  def upvotes_count
    comment_votes.where(vote_type: 'upvote').count
  end

  def downvotes_count
    comment_votes.where(vote_type: 'downvote').count
  end

  def is_upvoted(user)
    comment_votes.where(vote_type: 'upvote', user_id: user.id).exists?
  end

  def is_downvoted(user)
    comment_votes.where(vote_type: 'downvote', user_id: user.id).exists?
  end

  private

  def set_default_values
      self.upvote ||= 0
      self.downvote ||= 0
  end
end
