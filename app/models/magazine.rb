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

end
