class Post < ApplicationRecord::Base
    validates :title, length: { minimum: 0 }
end
