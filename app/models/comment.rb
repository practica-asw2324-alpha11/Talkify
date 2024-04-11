class Comment < ApplicationRecord
    belongs_to :user
    belongs_to :post

    after_initialize :set_default_values

    private

    def set_default_values
        self.upvote ||= 0
        self.downvote ||= 0
    end
end
