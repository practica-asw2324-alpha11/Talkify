class Comment < ApplicationRecord
    belongs_to :admin
    belongs_to :post

    after_initialize :set_default_values

    def self.order_by(sort_by)
        case sort_by
        when "top"
          order(upvotes_count: :desc)
        when "newest"
          order(created_at: :desc)
        when "oldest"
          order(created_at: :asc)
        else
          order(created_at: :desc) # Ordenar por defecto por fecha de creación
        end
    end

    private

    def set_default_values
        self.upvote ||= 0
        self.downvote ||= 0
    end
end
