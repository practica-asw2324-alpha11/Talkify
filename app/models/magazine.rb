class Magazine < ApplicationRecord
  has_many :posts
  has_many :comments, through: :posts
  has_and_belongs_to_many :admins

  def posts_count
    posts.count
  end

  def comments_count
    comments.count
  end

  def admins_count
    admins.count
  end

    def self.order_by(sort_by)
      case sort_by
      when "threads"
        order(posts_count: :desc)
      when "comments"
        order(comments_count: :desc)
      when "subscribers"
         order(admins_count: :desc)
      else
        order(created_at: :desc) # Ordenar por defecto por fecha de creación
      end
    end

end
