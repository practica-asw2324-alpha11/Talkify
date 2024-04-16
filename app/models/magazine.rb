class Magazine < ApplicationRecord
  has_many :posts
  has_many :comments, through: :posts
  has_and_belongs_to_many :admins
end
