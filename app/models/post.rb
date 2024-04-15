class Post < ApplicationRecord
    validates :title, length: { minimum: 0 }
    has_many :comments, dependent: :destroy
    has_many :votes, dependent: :destroy
    def comments_count
    comments.count
    end
    validates :url, presence: true, if: -> { is_link? }
    def is_link?
    link
  end

   def self.order_by(sort_by)
        case sort_by
        when "top"
          order(upvotes_count: :desc)
        when "newest"
          order(created_at: :desc)
        when "commented"
           Post.left_joins(:comments)
                 .group(:id)
                 .order('COUNT(comments.id) DESC')
        else
          order(created_at: :desc) # Ordenar por defecto por fecha de creación
        end
    end

      def upvotes_count
    votes.where(vote_type: 'upvote').count
  end

  def downvotes_count
    votes.where(vote_type: 'downvote').count
  end
end
