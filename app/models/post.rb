class Post < ApplicationRecord
    validates :title, length: { minimum: 0 }
end
