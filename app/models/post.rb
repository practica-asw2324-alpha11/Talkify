class Post < ApplicationRecord
    validates :title, length: { minimum: 0 }
    has_many :comments, dependent: :destroy
end
