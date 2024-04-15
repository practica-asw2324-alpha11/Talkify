class Post < ApplicationRecord
    validates :title, length: { minimum: 0 }
    has_many :comments, dependent: :destroy
    def comments_count
    comments.count
    end
    validates :url, presence: true, if: -> { is_link? }
    def is_link?
    link
  end
end
