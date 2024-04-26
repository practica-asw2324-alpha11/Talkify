class Magazine < ApplicationRecord
  validates :name, length: { minimum: 1 }
  validates :title, length: { minimum: 1 }
  has_many :posts
  has_many :comments, through: :posts
  has_and_belongs_to_many :users

  def posts_count
    posts.count
  end

  def comments_count
    comments.count
  end

  def users_count
    users.count
  end

end
