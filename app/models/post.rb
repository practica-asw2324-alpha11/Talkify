class Post < ApplicationRecord
    belongs_to :magazine
    belongs_to :user
    has_many :comments, dependent: :destroy
    has_many :votes, dependent: :destroy
    has_many :boosts, dependent: :destroy



    validates :title, presence: true, length: { minimum: 4 }
    validates :url, presence: true, if: -> { link }
    validates :magazine_id, presence: true


    def comments_count
    comments.count
    end


  def self.order_by(sort_by)
    case sort_by
    when "top"
      subquery = select('posts.*, SUM(CASE WHEN votes.vote_type = \'upvote\' THEN 1 ELSE 0 END) AS upvotes_count, SUM(CASE WHEN votes.vote_type = \'downvote\' THEN 1 ELSE 0 END) AS downvotes_count')
                   .left_joins(:votes)
                   .group('posts.id')

      from(subquery, :posts).order(Arel.sql('upvotes_count - downvotes_count DESC'))
    when "newest"
      order(created_at: :desc)
    when "commented"
      select('posts.*, COUNT(comments.id) AS comments_count')
        .left_joins(:comments)
        .group('posts.id')
        .order('comments_count DESC, created_at DESC')
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
